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
        }.navigationBarTitle(Text("Mug"))
    }
}

struct MugView: View {
    var selectedMug: Mug
    
    var body: some View {
        VStack {
            Text("\(selectedMug.username)")
            ImageViewContainer(imageUrl: selectedMug.avatarURL)
        }.navigationBarTitle(Text("Mug"))
    }
}

struct ImageViewContainer: View {
    @ObservedObject var remoteImageURL: RemoteImageURL

    init(imageUrl: String) {
        remoteImageURL = RemoteImageURL(imageURL: imageUrl)
    }

    var body: some View {
        Image(uiImage: UIImage(data: remoteImageURL.data) ?? UIImage())
            .scaledToFit()
    }
}

class RemoteImageURL: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    var data = Data() {
        didSet {
            objectWillChange.send()
        }
    }
    
    init(imageURL: String) {
        guard let url = URL(string: imageURL) else { return }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else { return }
            DispatchQueue.main.async { self.data = data }
        }.resume()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
