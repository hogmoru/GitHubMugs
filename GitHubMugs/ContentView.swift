//
//  ContentView.swift
//  GitHubMugs
//
//  Created by Hugues Moreau on 09/09/2019.
//  Copyright © 2019 Hugues Moreau. All rights reserved.
//

import Combine
import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            MasterView()
                .navigationBarTitle(Text("master_title"))
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

struct MasterView: View {
    @State private var searchText = ""
    @State private var errorMessage: String? = nil
    @State private var showingAlert = false
    @State private var mugs = [Mug]()
    @State private var searching = false
    @State private var searchTask : URLSessionDataTask? = nil

    var body: some View {
        ZStack(alignment: .center) {
            VStack {
                HStack {
                    TextField("search_text", text: $searchText, onCommit: self.startSearch)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .disabled(searching)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                    Button(action: self.startSearch) {
                        Image(systemName: "magnifyingglass")
                    }
                    .padding(.trailing)
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text("error"),
                          message: Text(self.errorMessage ?? "unknown_error"),
                          dismissButton: .default(Text("OK")))
                }
                List {
                    ForEach(mugs, id: \.username) { mug in
                        NavigationLink(
                            destination: DetailView(selectedMug: mug)
                        ) {
                            Text(mug.username)
                        }
                    }.onDelete { indices in
                        indices.forEach { self.mugs.remove(at: $0) }
                    }
                }
                .disabled(self.searching)
            }
            .blur(radius: self.searching ? 3 : 0)
            VStack {
                Text("searching_\(searchText)").padding()
                Button(action: self.stopSearchAndClear) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("stop_search")
                    }
                }
            }
            .padding()
            .frame(width: nil, height: nil, alignment: Alignment.topLeading)
            .background(Color.secondary.colorInvert())
            .foregroundColor(Color.primary)
            .cornerRadius(20)
            .opacity(self.searching ? 1 : 0)
        }
    }
    
    func startSearch() {
        if searchText == "" {
            stopSearchAndClear()
            return
        }
        searching = true
        searchTask = GitHubAPIClient.fetchMugs(search: self.searchText) { mugs, error in
            self.searching = false
            if error != nil {
                self.showingAlert = true
                self.errorMessage = error!
                self.mugs = [Mug]()
            } else {
                self.mugs = mugs
            }
        }
    }
    
    func stopSearchAndClear() {
        searching = false
        showingAlert = false
        searchText = ""
        mugs = [Mug]()
        if searchTask != nil {
            searchTask!.cancel()
            searchTask = nil
        }
    }
}

struct DetailView: View {
    var selectedMug: Mug?

    var body: some View {
        Group {
            if selectedMug != nil {
                MugView(selectedMug: selectedMug!)
            } else {
                Text("please_select_a_result")
            }
        }.navigationBarTitle(Text(selectedMug?.username ?? "Mug"))
    }
}

struct MugView: View {
    var selectedMug: Mug
    @State private var funkyEyes = true
    
    var body: some View {
        VStack {
            Toggle(isOn: $funkyEyes) {
                Text("funky_eyes")
            }.padding()
            ImageViewContainer(imageUrl: selectedMug.avatarURL, funkyEyes: funkyEyes)
            Button(action: self.openWebPage) {
                Image(systemName: "safari")
            }
            Spacer()
        }.navigationBarTitle(Text("\(selectedMug.username)"))
    }
    
    func openWebPage() {
        if let url = URL(string: "https://github.com/\(selectedMug.username)") {
            UIApplication.shared.open(url)
        }
    }
}

struct ImageViewContainer: View {
    @ObservedObject var imageSupplier: FunkyImageSupplier

    init(imageUrl: String, funkyEyes: Bool) {
        imageSupplier = FunkyImageSupplier(imageURL: imageUrl, funkyEyes: funkyEyes)
    }

    var body: some View {
        Image(uiImage: imageSupplier.uiImage)
            .resizable()
            .scaledToFit()
    }
}

class FunkyImageSupplier: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var uiImage = UIImage(systemName: "wand.and.stars")! {
        didSet {
            objectWillChange.send()
        }
    }
    
    init(imageURL: String, funkyEyes: Bool) {
        guard let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            var image = UIImage(data: data)!
            if (funkyEyes) {
                image = MugDecorator.faceOverlayImageFrom(image)
            }
            DispatchQueue.main.async { self.uiImage = image }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
