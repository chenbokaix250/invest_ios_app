import Foundation

actor FinnhubService {
    private let baseURL = Constants.API.finnhubBaseURL
    private let apiKey: String
    private let session: URLSession

    init(apiKey: String = APIKeys.finnhubAPIKey) {
        self.apiKey = apiKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    func fetchCompanyProfile(symbol: String) async throws -> CompanyProfile {
        guard let url = URL(string: "\(baseURL)/stock/profile2?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        // Parse JSON response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return CompanyProfile(
                name: json["name"] as? String ?? "",
                ticker: json["ticker"] as? String ?? symbol,
                exchange: json["exchange"] as? String ?? "",
                industry: json["finnhubIndustry"] as? String ?? "",
                description: json["description"] as? String ?? "",
                logo: json["logo"] as? String,
                website: json["weburl"] as? String
            )
        }

        return CompanyProfile(
            name: "", ticker: symbol, exchange: "", industry: "",
            description: "", logo: nil, website: nil
        )
    }

    func fetchFinancials(symbol: String) async throws -> Financials {
        guard let url = URL(string: "\(baseURL)/stock/financials?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await session.data(from: url)

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let data_ = json["data"] as? [[String: Any]],
           let first = data_.first {
            return Financials(
                revenue: first["revenue"] as? Double ?? 0,
                netIncome: first["netIncome"] as? Double ?? 0,
                grossMargin: first["grossMargin"] as? Double ?? 0,
                peRatio: first["peBasicExclExtraTTM"] as? Double ?? 0,
                eps: first["epsBasicExclExtraItems"] as? Double ?? 0
            )
        }

        return Financials(revenue: 0, netIncome: 0, grossMargin: 0, peRatio: 0, eps: 0)
    }

    func fetchPeerComparisons(symbol: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/stock/peers?symbol=\(symbol)&token=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await session.data(from: url)

        if let peers = try? JSONSerialization.jsonObject(with: data) as? [String] {
            return peers
        }
        return []
    }

    func fetchSentiment(symbol: String) async throws -> Sentiment {
        // Finnhub sentiment API - simplified
        return Sentiment(buy: 0, sell: 0, hold: 0)
    }

    struct CompanyProfile {
        let name: String
        let ticker: String
        let exchange: String
        let industry: String
        let description: String
        let logo: String?
        let website: String?
    }

    struct Financials {
        let revenue: Double
        let netIncome: Double
        let grossMargin: Double
        let peRatio: Double
        let eps: Double
    }

    struct Sentiment {
        let buy: Double
        let sell: Double
        let hold: Double
    }
}