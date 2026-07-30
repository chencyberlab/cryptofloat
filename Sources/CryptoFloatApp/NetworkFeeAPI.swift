import Foundation

// MARK: - Network Fee API Manager
class NetworkFeeAPI {
    static let shared = NetworkFeeAPI()
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    private let ethereumRPCURLs = [
        URL(string: "https://eth-mainnet.g.alchemy.com/public")!,
        URL(string: "https://cloudflare-eth.com")!
    ]
    private let bitcoinFeeURL = URL(string: "https://mempool.space/api/v1/fees/recommended")!
    private let bitcoinMempoolBlocksURL = URL(string: "https://mempool.space/api/v1/fees/mempool-blocks")!
    private let blockstreamFeeURL = URL(string: "https://blockstream.info/api/fee-estimates")!
    private let blockchairBitcoinStatsURL = URL(string: "https://api.blockchair.com/bitcoin/stats")!
    private let blockcypherBitcoinURL = URL(string: "https://api.blockcypher.com/v1/btc/main")!
    private let bitcoinerLiveFeeURL = URL(string: "https://bitcoiner.live/api/fees/estimates/latest?confidence=0.8")!

    private let ethTransferGas: Double = 21000

    private func requestGET(_ url: URL, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network fee GET error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let data = data,
                  !data.isEmpty,
                  data.count <= 5_000_000 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Network fee request failed with HTTP status \(status)")
                DispatchQueue.main.async { completion(nil) }
                return
            }

            DispatchQueue.main.async { completion(data) }
        }.resume()
    }

    private func requestEthereumFeeHistory(
        urls: [URL],
        body: [String: Any],
        completion: @escaping (EthereumFeeHistory?) -> Void
    ) {
        guard let url = urls.first else {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            let statusIsValid = (response as? HTTPURLResponse)
                .map { (200..<300).contains($0.statusCode) } ?? false
            let parsed = data.flatMap { payload -> EthereumFeeHistory? in
                guard payload.count <= 5_000_000 else { return nil }
                return EthereumFeeHistoryParser.parse(
                    payload,
                    expectedBlockCount: 6
                )
            }

            if error != nil || !statusIsValid || parsed == nil {
                self.requestEthereumFeeHistory(
                    urls: Array(urls.dropFirst()),
                    body: body,
                    completion: completion
                )
                return
            }
            DispatchQueue.main.async { completion(parsed) }
        }.resume()
    }

    private func fetchEthereumFees(ethPrice: Double?, completion: @escaping ([NetworkFeeTier]) -> Void) {
        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "eth_feeHistory",
            "params": ["0x6", "latest", [10, 50, 90]],
            "id": 1
        ]

        requestEthereumFeeHistory(urls: ethereumRPCURLs, body: body) { history in
            guard let history = history,
                  history.averagePriorityFeesWei.count >= 3 else {
                completion([])
                return
            }

            let tiers: [(String, Int, String)] = [
                ("Slow", 0, "1-2m"),
                ("Standard", 1, "~30s"),
                ("Fast", 2, "~15s")
            ]

            let feeTiers = tiers.map { label, index, eta -> NetworkFeeTier in
                let priorityWei = history.averagePriorityFeesWei[index]
                let gwei = (history.nextBaseFeeWei + priorityWei) / 1_000_000_000
                let usd = ethPrice.map { gwei * self.ethTransferGas / 1_000_000_000 * $0 }
                return NetworkFeeTier(label: label, rate: gwei, unit: "gwei", usdValue: usd, eta: eta)
            }

            completion(feeTiers)
        }
    }

    private func fetchBitcoinFees(btcPrice: Double?, completion: @escaping ([NetworkFeeTier]) -> Void) {
        let group = DispatchGroup()
        var estimates: [BitcoinFeeEstimate] = []

        func fetch(_ url: URL, parse: @escaping (Data?) -> BitcoinFeeEstimate?) {
            group.enter()
            requestGET(url) { data in
                if let estimate = parse(data) {
                    estimates.append(estimate)
                }
                group.leave()
            }
        }

        fetch(bitcoinMempoolBlocksURL) {
            $0.flatMap { BitcoinFeePayloadParser.mempoolBlocks(from: $0) }
        }
        fetch(bitcoinFeeURL) {
            $0.flatMap { BitcoinFeePayloadParser.mempoolRecommended(from: $0) }
        }
        fetch(blockstreamFeeURL) {
            $0.flatMap { BitcoinFeePayloadParser.blockstream(from: $0) }
        }
        fetch(blockchairBitcoinStatsURL) {
            $0.flatMap { BitcoinFeePayloadParser.blockchair(from: $0) }
        }
        fetch(blockcypherBitcoinURL) {
            $0.flatMap { BitcoinFeePayloadParser.blockcypher(from: $0) }
        }
        fetch(bitcoinerLiveFeeURL) {
            $0.flatMap { BitcoinFeePayloadParser.bitcoinerLive(from: $0) }
        }

        group.notify(queue: .main) {
            guard let estimate = BitcoinFeeCalculator.conservativeEstimate(
                from: estimates
            ) else {
                completion([])
                return
            }

            let tiers = BitcoinFeeCalculator.tiers(
                from: estimate,
                btcPrice: btcPrice
            )
            completion(tiers)
        }
    }

    func fetchFees(ethPrice: Double?, btcPrice: Double?, completion: @escaping (NetworkFeeData) -> Void) {
        let group = DispatchGroup()
        var ethFees: [NetworkFeeTier] = []
        var btcFees: [NetworkFeeTier] = []

        group.enter()
        fetchEthereumFees(ethPrice: ethPrice) { fees in
            ethFees = fees
            group.leave()
        }

        group.enter()
        fetchBitcoinFees(btcPrice: btcPrice) { fees in
            btcFees = fees
            group.leave()
        }

        group.notify(queue: .main) {
            completion(NetworkFeeData(
                eth: ethFees,
                btc: btcFees,
                updatedAt: Date(),
                hasError: ethFees.isEmpty && btcFees.isEmpty
            ))
        }
    }
}
