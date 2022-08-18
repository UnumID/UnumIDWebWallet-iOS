import SwiftUI
import HyperKYC
import UnumIDWebWallet

@main
struct SampleApp: App {
    @State var parameters: Parameters?
    @State var loading = false
    @State var name: String?
    @State var isPresented: Bool = false
    
    var completion: ((_ result: HyperKycResult) -> Void)?
    
    init() {
    }
    
    var keyWindow: UIWindow? {
        UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }
    
    var rootViewController: UIViewController? {
        keyWindow?.rootViewController
    }
    
    var body: some Scene {
        WindowGroup {
            if loading {
                LoadingView()
            } else {
                ContentView(buttonAction: showHyperKyc, name: $name)
                    .launchWebWallet(isPresented: $isPresented, parameters: parameters)
            }
        }
    }
    
    private func showHyperKyc() {
        guard let vc = rootViewController else { return }
        HyperKyc.launch(
            vc,
            hyperKycConfig: HyperKycConfig(
                appId: Constants.appId,
                appKey: Constants.appKey,
                workflowId: Constants.workflowId,
                transactionId: [
                    Constants.transactionId, "_", UUID().uuidString
                ].joined()
        ), { result in

            guard let status = result.status else { return }
            
            switch status {
            case .success:
                loading = true
                
                let doc = result.hyperKYCData?.docResultList.first
                let dataList = doc?.docDataList.first
                let responseResult = dataList?.responseResult?.result
                let details = responseResult?.details?.first
                let fields = details?.fieldsExtracted
                
                let faceResult = result.hyperKYCData?.faceResult
                let faceData = faceResult?.faceData
                let path = faceData?.croppedFaceImagePath
                
                do {
                    let url = URL(fileURLWithPath: path ?? "")
                    let docImage = try Data(contentsOf: url).base64EncodedString()
                    try UnumID.shared.sendRequest(
                        input: RequestValue.init(
                            dob: fields?.dateOfBirth?.value ?? "",
                            address: fields?.address?.value ?? "",
                            fullName: fields?.fullName?.value ?? "",
                            gender: fields?.gender?.value ?? "",
                            docImage: docImage
                        )
                    ) { result in
                        
                        loading = false
                        name = fields?.fullName?.value ?? ""
                        
                        switch result {
                        case .success(let result):
                            let issuer = Constants.issuerDid
                            self.isPresented = true
                            self.parameters = Parameters(
                                status: status == .success,
                                userCode: result.userCode,
                                issuer: issuer
                            )
                            debugPrint(result.userCode)
                        case .failure(let error):
                            debugPrint(error.localizedDescription)
                        }
                    }
                } catch {
                    debugPrint(error.localizedDescription)
                }
            case .cancelled, .failure:
                loading = false
            @unknown default:
                loading = false
            }
        })
    }
}

extension HyperKycResult: ObservableObject {}
