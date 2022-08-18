import UIKit
import UnumIDWebWallet
import HyperKYC

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "faceId"), for: .normal)
        button.tintColor = .white
        button.setTitle("Authorize", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemGreen
        view.addSubview(button)
        view.addConstraints([
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        button.addTarget(self, action: #selector(showHyperKyc), for: .touchUpInside)
    }
    
    @objc private func showHyperKyc() {
        HyperKyc.launch(
            self,
            hyperKycConfig: HyperKycConfig(
                appId: Constants.appId,
                appKey: Constants.appKey,
                workflowId: Constants.workflowId,
                transactionId: [
                    Constants.transactionId, "_", UUID().uuidString
                ].joined()
            ), { [weak self] result in
                guard let self = self else { return }
                guard let status = result.status else { return }
                
                switch status {
                case .success:
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
                            
                            switch result {
                            case .success(let result):
                                let issuer = Constants.issuerDid
                                let parameters = Parameters(
                                    status: status == .success,
                                    userCode: result.userCode,
                                    issuer: issuer
                                )
                                WebWallet.associate(on: self, with: parameters)
                                
                            case .failure(let error):
                                debugPrint(error.localizedDescription)
                            }
                        }
                    } catch {
                        debugPrint(error.localizedDescription)
                    }
                case .cancelled, .failure:
                    return
                @unknown default:
                    return
                }
            })
    }
}
