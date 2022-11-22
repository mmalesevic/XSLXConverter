//
//  ContentView.swift
//  xslx to json
//
//  Created by Matej Malesevic on 18.11.22.
//

import SwiftUI
import CoreXLSX
enum LoadingState {
    case initial, loading, success, error
}
struct ContentView: View {
    @State private var path: URL? = nil
    @State private var jsonObject: String = ""
    @State private var jsonAsData: Data? = nil
    @State private var loadingState: LoadingState = .initial
    
    fileprivate func convertData() {
        Task {
            do {
                let entries = try await Converter.convert(from: path)
                jsonAsData = try JSONSerialization.data(withJSONObject: entries)
                jsonObject = "success"
                loadingState = .success
            } catch Converter.Error.fileCannotBeFound(let filePath) {
                loadingState = .error
                jsonObject = "file (\(filePath)) cannot be opened"
            } catch {
                loadingState = .error
                jsonObject = """
    unknown error occured:
    
    \(error)
    """
            }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView(showsIndicators: true) {
                if loadingState == .initial {
                    Text("please choose a file Convert")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if loadingState == .loading {
                    ProgressView()
                        .padding(.vertical)
                } else if loadingState == .error {
                    VStack {
                        Text("error while loading data")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Divider()
                        Text(jsonObject)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    Text(jsonObject)
                        .lineLimit(nil)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Divider()
            
            HStack{
                if let path = path {
                    Label(path.absoluteString, systemImage: "doc.text.fill")
                }
                Spacer()
                if let jsonData = jsonAsData {
                    Button {
                        
                        let savePanel = NSSavePanel()
                        savePanel.title = "Save JSON"
                        savePanel.nameFieldLabel = "JSON Name:"
                        savePanel.nameFieldStringValue = "data"
                        savePanel.prompt = "Save"
                        savePanel.allowedContentTypes = [.json]
                        
                        do {
                            if case .OK = savePanel.runModal(), let url = savePanel.url {
                                try jsonData.write(to: url)
                            } }
                        catch {
                            print("error when saving file")
                        }
                        
                    } label: {
                        Label("save json", systemImage: "arrow.down.doc.fill")
                    }
                }
                Button {
                    loadingState = .loading
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    
                    if case .OK = panel.runModal() {
                        path = panel.url
                        
                        convertData()
                    }
                } label: {
                    Label("load *.xlsx", systemImage: "arrow.up.doc.fill")
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
