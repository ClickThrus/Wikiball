import CoreGraphics
import CoreImage
import Foundation
import Vision

actor WikipediaPlayerImageService {
    static let shared = WikipediaPlayerImageService()

    private let context = CIContext(options: [.cacheIntermediates: true])
    private var cache: [String: CGImage] = [:]

    func cutout(for title: String) async -> CGImage? {
        if let cached = cache[title] { return cached }
        guard let imageURL = await thumbnailURL(for: title),
              let (data, response) = try? await URLSession.shared.data(from: imageURL),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let input = CIImage(data: data) else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(ciImage: input)
        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            let cutout = CIImage(cvPixelBuffer: buffer)
            guard let image = context.createCGImage(cutout, from: cutout.extent) else { return nil }
            cache[title] = image
            return image
        } catch {
            return nil
        }
    }

    private func thumbnailURL(for title: String) async -> URL? {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "prop", value: "pageimages"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            URLQueryItem(name: "pithumbsize", value: "1200"),
            URLQueryItem(name: "redirects", value: "1"),
            URLQueryItem(name: "titles", value: title),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "origin", value: "*")
        ]
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 12
        request.setValue("Wikiball-iOS/1.0 (football trivia; Wikipedia attribution in app)", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let root = try? JSONDecoder().decode(PageImageResponse.self, from: data) else { return nil }
        return root.query.pages.first?.thumbnail?.source
    }
}

private struct PageImageResponse: Decodable {
    let query: Query

    struct Query: Decodable { let pages: [Page] }
    struct Page: Decodable { let thumbnail: Thumbnail? }
    struct Thumbnail: Decodable { let source: URL }
}
