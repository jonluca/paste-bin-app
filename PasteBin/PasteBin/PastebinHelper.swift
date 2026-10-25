//
//  PostHelper.swift
//  PasteBin
//
//  Created by Henrik Gustavii on 04/04/2018.
//  Copyright © 2018 JonLuca De Caro. All rights reserved.
//

import AFNetworking
import Foundation

class PastebinHelper: UIViewController {
    // MARK: - Post to Pastebin methods

    func postToPastebin(text: String, savedList originalSavedList: [String], syntax: String = "", titleText: String = "") {
        var responseString: String = ""

        if isInternetAvailable() {
            let defaults = UserDefaults.standard

            // Our dev key
            let api_dev_key = "&api_dev_key=" + "71788ef035e5bf63bbbd11945bd8441c"
            var api_paste_private = "&api_paste_private="

            // Unlisted or not (0=public 1=unlisted 2=private)?
            api_paste_private += defaults.bool(forKey: "SwitchState") ? "1" : "0"

            var api_paste_name = "&api_paste_name="

            // name or title of your paste

            let qpTitle = defaults.string(forKey: "quickPasteTitle") ?? "Created with Pastebin Mobile"

            let finalTitleText: String = titleText.isEmpty ? qpTitle : titleText

            api_paste_name += finalTitleText

            let api_paste_expire_date = "&api_paste_expire_date=" + "N"

            var api_paste_format = "&api_paste_format="

            // defaults quickpaste to no syntax i.e. "text"
            api_paste_format += syntax.isEmpty ? "text" : syntax

            let api_user_key = "&api_user_key=" + ""
            // if an invalid api_user_key or no key is used, the paste will be create as a guest
            let encoded_text = "&api_paste_code=" + (text.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))!

            // URL Acceptable string
            let encoded_title = api_paste_name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)

            var request = URLRequest(url: URL(string: "https://pastebin.com/api/api_post.php")!)
            request.httpMethod = "POST"

            // convoluted but necessary for their post api
            var postString = "api_option=paste"
            postString += api_user_key
            postString += api_paste_private
            postString += encoded_title!
            postString += api_paste_expire_date
            postString += api_paste_format
            postString += api_dev_key + encoded_text

            request.httpBody = postString.data(using: .utf8)
            // POST request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    // if not connected to internet
                    print("error=\(String(describing: error))")
                    return
                }

                if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 { // check for http errors
                    print("statusCode should be 200, but is \(httpStatus.statusCode)")
                    print("response = \(String(describing: response))")
                    let alertController = UIAlertController(title: "Error!", message: "Unknown error - HTTP Code" + String(httpStatus.statusCode), preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default) { _ in
                        // handle response here.
                    }
                    alertController.addAction(OKAction)
                    UIApplication.topViewController()?.present(alertController, animated: true) {}
                }

                responseString = String(data: data, encoding: .utf8)! // Not happy about this forced unwrap

                // Adding the link to the savedList array and then saving to drive
                var savedList: [String] = originalSavedList
                savedList.append(responseString)
                self.saveSavedListItems(savedList: savedList)

                let alertController = UIAlertController(title: "Success!", message: responseString + "\nShare link or copy to clipboard?", preferredStyle: .alert)
                let shareAction = UIAlertAction(title: "Share", style: .default) { _ in

                    let itemURL = URL(string: responseString)
                    let vc = UIActivityViewController(activityItems: [itemURL ?? "No link found"], applicationActivities: [])
                    UIApplication.topViewController()?.present(vc, animated: true)
                    print("responseString to share = \(String(describing: itemURL))")
                }
                let copyAction = UIAlertAction(title: "Copy", style: .default, handler: { _ in

                    UIPasteboard.general.string = responseString
                    print("responseString to copy = \(String(describing: responseString))")

                })

                alertController.addAction(shareAction)
                alertController.addAction(copyAction)
                UIApplication.topViewController()?.present(alertController, animated: true) {}
            }
            task.resume()

        } else {
            let alertController = UIAlertController(title: "Error!", message: "Not connected to the internet!", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { _ in
                // handle response here.
            }
            alertController.addAction(OKAction)
            UIApplication.topViewController()?.present(alertController, animated: true) {}
        }
    }

    // MARK: - Save and load file/items/list methods

    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("SavedList.plist")

    func saveSavedListItems(savedList: [String]) {
        let encoder = PropertyListEncoder()

        do {
            let data = try encoder.encode(savedList)
            try data.write(to: dataFilePath!, options: Data.WritingOptions.atomic)
        } catch {
            print("Error encoding item array!")
        }
    }

    func loadSavedListItems() -> [String] {
        var savedList: [String] = []
        if let data = try? Data(contentsOf: dataFilePath!) {
            let decoder = PropertyListDecoder()
            do {
                savedList = try decoder.decode([String].self, from: data)
            } catch {
                print("Error decoding item array!")
            }
        }

        return savedList
    }

    // MARK: - Internet availability check method

    // credit to http://stackoverflow.com/questions/39558868/check-internet-connection-ios-10
    // Simple check if internet is available
    func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}

// MARK: - Return topViewController Extension

// credit to https://stackoverflow.com/questions/40015171/how-to-show-an-alert-from-another-class-in-swift
extension UIApplication {
    static func topViewController(base: UIViewController? = UIApplication.shared.delegate?.window??.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }
}
