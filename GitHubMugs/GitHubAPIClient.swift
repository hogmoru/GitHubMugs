//
//  GitHubAPI.swift
//  GitHubMugs
//
//  Created by Hugues Moreau on 09/09/2019.
//  Copyright © 2019 Hugues Moreau. All rights reserved.
//

import Foundation

typealias GitHubAPICompletionHandler = (_ result: [Mug], _ error: String?) -> Void

struct Mug {
    let username: String
    let avatarURL: String
}

struct GitHubAPIClient {
    
    static func fetchMugs(search: String, onCompletion: @escaping GitHubAPICompletionHandler) -> URLSessionDataTask {
        let safeSearch = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: "https://api.github.com/search/users?q=\(safeSearch!)")!
        /*
         {
         "total_count": 430,
         "incomplete_results": false,
         "items": [
           {
             "login": "jsmith",
             "id": 123,
             "avatar_url": "https://avatars2.githubusercontent.com/u/39813?v=4",
            ...
           },
           ...
         ]}
         */
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                if error != nil {
                    if  (error! as NSError).code != NSURLErrorCancelled {
                        onCompletion([Mug](), error!.localizedDescription)
                    }
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let items = json["items"] as? [[String: Any]] {
                        var mugs = [Mug]()
                        for item in items {
                            let login = item["login"] as! String
                            let avatar = item["avatar_url"] as! String
                            let mug = Mug(username: login, avatarURL: avatar)
                            mugs.append(mug)
                        }
                        onCompletion(mugs, nil)
                        return
                    }
                }
            } catch {
                print("Error")
            }
            onCompletion([Mug](), error?.localizedDescription ?? "Failed to retrieve results")
        }
        task.resume()
        return task
    }
}
