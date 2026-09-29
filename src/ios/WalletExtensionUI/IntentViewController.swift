import IntentsUI
import Foundation
import UIKit
import PassKit
import LocalAuthentication
import Security
import CryptoKit
import CommonCrypto
import os

let BASE_URL = "https://extapigw-uat.bh.kfh.com"
let encryptionKey = "77889900112277889900112277889900"
let certPassword = "P@ssw0rd"
let ivString = "PGKEYENCDECIVSPC"
let entity = AUBEntity.AUBBH
let appGroupID: String = "group.com.aub.mobilebanking.uat.bh"
let identity_value = "MIIXMQIBAzCCFu0GCSqGSIb3DQEHAaCCFt4EghbaMIIW1jCCBhcGCSqGSIb3DQEHAaCCBggEggYEMIIGADCCBfwGCyqGSIb3DQEMCgECoIIE7jCCBOowHAYKKoZIhvcNAQwBAzAOBAjgdfA5ppb0hQICB9AEggTI+RzYkxH6ezDlQePAg/X0fSPY2jfPDDJWzmuVAvrOFN40+0iEfmXZy7bpccyphBtN7O0WmAjWFkoJCJr3Zw4pFrFVLGFjUTudjPznvMMW0u+gKWo6t2SapQwU0PXs17NYCOjHN3pGBW/VaoCCnGLKqmFAfh2Oj4GzNQZj/MTesFzUKf6rxW11opP8EZmUI9QcjF07xD85LRvicVpdIq7jfDqk9s455uIrVzwVcRmFM+Vz4p+O4Pk6BpnLqXggRb4fghCeI+eWbhBTeYWBOzx6oFLH4YpNIh05rDZMt+8LOCpK4Fr2qYDcz2+6lIQ2An8Q063gYqX1SqueFIqd1waev26dtkso7YeElPWcmZNIzxc3kA3L2G3cNmlZRC4JuBa+sh78hq03QDyamjX6VYg3pgUdIWjoV0y/fCWFCY4AGc83wvNol0G0HELJj753Ne4AJ55Mbd104YflkFQ0laJar6ehicecpCVdtiVSvOQBIao8sbiZCrBKp7UQ5Dljuqg9uNRlYBMSmqL5zc0Xh2MoA+cpX8e9QkWiNf6veTaoeNaYENqdBe7bBCUClP88WJHEWgnM/KgWlU9dbU4tNaHESZwqmMutGKPIR64I3E2cZkKQRWa1SaOJcI51iNHXnoSBTY+NvS5AbVUsjp/toAW0eIv786+V4CQZbkHV2nGyIipxHDMLyjS+Vuba7+XJ8VSAo4SeeJtMCHgCC5evfqev1gZPvA+lMEKjSbmacknQpDawYn2+wK0Zpy/vrJi0CxmKqUxCZfm2yujEKUkqzzUSEeCrMW9wZO/Q0dBZ4T3QMnjpju7/KlkxmnSJbB29pZ0Z7DtRxidbjasZAyBJ+2zYoj4db93mq8K3jscOU3Ju1DYnqyu5YuvvNyP21Ho/tqk8jVt8Ks7cV6mYjTj/jBFs1N+5Dq3vJrxJulTkcO8ea6MuqHDn/6Gtuv7SQBixvbN3q0l2z42z2eo0W8oEqKw+bsO6eNk9FsbNgLaDZGmIx6kMlRtev9maZpoYD4xqiE1kc8ihvZkxUtd8ApGlOsIJbcfXOno3fbIyX4vUAZIntzyyK0dot+A/d8jIR9efwUQ3cDl8zAutrkiRadXuSWgI/z8rRN6Fbeezb5DASZIBZjnyWPct613tKSroGGlG6jxqzPZWIui/WTg9eiGEToAv1BsVkcOR7dcoPWUsRBVn/qgQkz5PAPhZl8stBbOl5AsLWYf2OWAPKKbFsHtK3SBEyIST+NGLYwRsjUSl39X2ab37yDEB5PwdFRY8OruDPV+Ba5R45yroCsVUPF851kJiW7MfcJ2lcf4/Ue9ATTtWNRXdYLuHq2+8LSxG1ltkYtZDRrZ+PIFecjfIS9/izLZKAS++gXRd66LMM1/SbnpXnoLWMOj97vy3H6kHHVVWN2r15Cfly2yV8MP8jWV1IyOTjC0A+cni+OkV8+s9Wh3ePxsaSHo0XLVU4/ys8RJexxyh2iAZQ+gsRZIf2q/M6MlhGKslFl+VRjReWPPDWX14k/jdtLaKv7mgoOqVjezcXPYXAIOOOBI+ulZiPuEiZyD4LBY4KTNfwtn54t4gd42krsyqHI6PNP1V0uvYs4+5bmwzX/iBYloHsYqPpeqAk5Bf+FKNEEBbaqiwMYH6MA0GCSsGAQQBgjcRAjEAMBMGCSqGSIb3DQEJFTEGBAQBAAAAMF0GCSsGAQQBgjcRATFQHk4ATQBpAGMAcgBvAHMAbwBmAHQAIABTAG8AZgB0AHcAYQByAGUAIABLAGUAeQAgAFMAdABvAHIAYQBnAGUAIABQAHIAbwB2AGkAZABlAHIwdQYJKoZIhvcNAQkUMWgeZgB0AGUALQBXAGUAYgBTAGUAcgB2AGUAcgBWADMALQA0ADQAYwAxAGYANwAyAGUALQA1ADEANwAwAC0ANABmADYAMwAtADkANwAxAGUALQA1ADcAYQBhADIAOABkADEAOQAyADMAYTCCELcGCSqGSIb3DQEHBqCCEKgwghCkAgEAMIIQnQYJKoZIhvcNAQcBMBwGCiqGSIb3DQEMAQMwDgQI2UyeWhhMHzcCAgfQgIIQcEjKsvz+XUk4VfmyuvjzZV+/4wUa5jLYTj2gpwBrweiMTLkYpQTEcj85CyD/xnQwz791LeOXS8C4M932ix+v7janN8xYmeEzHaRyaQhYjOjPuihkcVAYiGuwVVCNqGMiIxYBZVfOEBiuW3oeU0YvFKtpf89EwG1OV+5x8X1Ovj+bJshny+UHDkFV4QrSsPtR5ylXk+d1H459HqqR61tMYRawLLP3BsgSpb76Uv7EO+CPV9yGoSrfySdHqMFb0ixjGnzRKV+ezQgokWTQSRi+rYMA7W9JdCvGolBkx4bMASismTEsJ81yfVLS6tPcfQCU3/13SEATmfTgmFGpVwyRk3y/B8OGuxvVhfx1+njJQGA/KD07c3QR9Qrm6xnlXN9BTHGfEF4x+//q0qoanUa2zJ6yRS1OLhMikC5GBT8McLSULe/gigj9HbEkWanDZYEIk5jGe1BsrO8tOmlADaV3xCr8c+en/xu5t2vy5tVMoUUBYV0n6V2KI7Ud06i1q7yXKsz2tvIMzgVNp9nUYH3725wSbGtz6JCBuraxf+tNJT7FbRZNTj2zKrgZYyFLxErzdsxSskWjSKk2fIELBeE3SvwVLg3rwegwSgKD9gewWbHeLL21CHTiTO4QVcahPa8Ne4j6+QwxVDffJs3PdX4oe26hdtxgEnF7fqH1F3B7XQovlpFBaA/5LbtWt8iSSLwEWnhjlAom03y95wM1udwL49N6tI4a6NVKewP/VAwZ5llrl8ug1/vtKeedzezrLe08AEWfc5km0QM/OC8jC6aiVbTJ4Cs76fcEgEG37DoI6hS70Yxri0MGw27HLzUIqKniXrLOnsskFxN/mXZWDC0w02N6XLzyatUWsEvKf+pfJ6iN6nuTP01EKTFwskkBIXMxRwrVojPU/8bbEk+Q4GpAQt5qZwXoxWMQR3p2XV8YtUGriX3K32s6FLZqCz11QJWh+s+iOCUzfEoQECfwbBmuYhDzUEzBM9C9qm7dXDXx/725mfHbaf0CwVKqL1ePzaC22mZzbquOlmtHAYfihqgnGuBlL0YfMMPp/abEOFfOC0n5P28bNqk164ba4uszu7csBUhelmx4TIQEQ9H5SvfT5r6J4Pc4AaaQZ14OQNJF5AtnArH4VedaU3IwnSikw3y6awTd56lO+1XI+hBChBA9UmxE/dSPP7Lc8C+6/WYRW1isOt6RQrk+ATYKd70VbpbU5U/lj6qGBl95RiR90SDhkBZLh/Ol3jtgLpWcEaUNk8WWulPl+3BzoBh5vS1FllmGA/XlYLilC1Hxy3XVZSY2HJ03f9fqVlOGiZ6N43Iy45t44s6xYQ5Khq5FTaia5y+9CftWhF4oZweMUbPrXfYSsjw4P12vgvIs2cN+3ZEeigQWMpqEMnCVpnlAGO9QMstDI8p0M+LAb2CzERL3ygTq7G5JpWhWcfqMXs+C0Tn0v8k2tAO92Oe1E9DBQ1qBEtD8NS/oNE4Ln58JVsqWWEYm9gxWHMaGMDxlq6trmpqxQBj686nEwjFtXsrB8p38w/VE9c5AFXN0ItH3dajEE2671Fnb1mNdIyzcB2wXOqLkUTHiO3OipIUnOfDPYPZxm5PRAg45ABj6Ljx41C43lxvlb7pM8EEw3oUHwDuZ7ytGetx27b8FX8z0dBoS93mRh/e3FR4nNaNS0rgghwPkYkJJtZU6DmW2jLWwvYYcanIFyJ5WV/aQd70f9Ov4fbN8WnmLZtviBCtWVT3kNdG/v9NVsI+8HnqRztzr0opWBMFc/aNhIAeqSANfDdRraEwCOUr0RAQ2aVtKRPgbgzjait5pmbIGzKq3gNn8OGuptPc6W284zns/339nZnTrUb1dBtxmhxE0c1NAQ1eqI1aJQqZlBLRR6Z0eKIEf5hlGEolh5e5xFzuBQUmhGb0wOxVvorPVF8mowhLRXghcw4lg9wnAjG8puqbQOFI4PNxso5+vtn6d4vlUZjXxXrx0tYSGig+GTiB/xjfwzyMrMuPWtEVIfVucns3laWF7294pkpKRDYTgm0Hp7AQDBvrzDUUDahXnhxOWgR8Vc9ZMCnPVLojMsupcC1nnz0NYJiG62Vbc4lOMHebjROCgA7R/gpQzbBMFspW0dc6QHfV/i6pLKn7eale2pbBCgqKUL0gZPgsm2wyDH78rYuqT83amkwrlr43M355sx1wb3ub6ghDtodv4+4pLfDfUMCqKpj+WKBO9w0FfU/uFHdm9eMAPFltfk4GFvgvDe4JlxUSgS0yWOe1epw6w22vyhUWalQDZmJDzPr2E9r3gyTKeTqBOjs0ElUoRj17/pbsSTiBXnmDu0NlgPtCSMd57X6JLsEvSKVj8k0mZ4y0nHwBrfKCI72CsrrBb7rQOzeN/Py5O4+QVOCAmR5Epd9HrebYXwzOkZIn98ipqXlGd4HP4YHwXlHLM1I+ZDDkZi3hFUqaGLCttjWQkmLBAH79ZsUTLkJr10OX04W/lhA+pYVl5dM8bximrh9tPGHhHb8frjMj2dt9cXc7+jACLfiZRvVZUJewpEkMeSujTVrfbb6VN7pj201cl4U40BSIM7eRPaCtJpjUj0PrmaJpndwGAg/nn/P9YS8IZkZyinKxhpA9U666xythhTvzcYE1leVDCkQAPP/CRkIhJv95Jz0sDL8e599x1xRtJRNqe3Sbs2TwO+FLLeWy1q4Q+7U08+MaKge0cIofBPyKMdlqDntWcMvRXB6bzFQMPHs9Vr4QzQPvoRYQAwnEw892wLRUPQxtEPIrmTWcteGKVYDnbMCK/rgERIXphsDaeRJWjrQ4Oqoy43m1mH7SS+ibJC3RdZO1B4Lou9/RZ6E6SsrB+GArhd8Nds+YhY+RuQIHQzrLeMBgynaQiCtd4mgjwE0j5noFL2PxAxL7Ku9K9cfSKRivUsZbtxZ+XfEcGeLWYhll3cvIeHHieG4AF63lfo5ctzp4ERIJo8QtCSoUVMaLiRHAe4+Hr9iF0f9dnmgTYQxZOXaLhFowXUWBgtDik2lVV+Hw8WSGBy8yoNmlByqEEfNkZUbQJrdOYMmAWDQks9oKH4e0KlprzsFbkG/G/6sfvLpVYBcWbPVGh7lGOGsiGmoFnZRBbjLd31U4wq5BVbsVtBVFWS3VEBOvYoVh+xhSZBNSl3MdgyuwJWPEllWrCXM9+GyURRvyeCKNWonDXFLlVTZAMOEzu2HC+thTpzUHYzx7S4jI3VBxRmQQbaxoJ2cpoAO4bAklZWyNIv8PdgYe3YOJBZUJv3PWUipY/+lE3sFYkuag0tdEE0IRO9/PrCEI6c6XJaqmEDuDICzSVi7i8Gb+fpu3vFDuX2jaPrFF5e9wK+AwuksKw0TGo7Y4oi7EHgMqY+6e6SpEl4SZF2kvwRpiDBUV9eykp7WWmPY+rV2WmehDCvmRBFkx9+wcO1BpywLBBiMbL68KV+oTQaVVcg2Hu3+dp0eeItKrKbIAbd1Fcr6QtwAhWFeCGh9/XeeTYe56iaR5a85qlui03PVV34yxwFQOkduIvr10/HwT4Ykd6B4KLlbcjs6o6+Y+WPYoFM3QVsLAsGEhaLIg8ltqPI6M16aA+6Pva/Lsyb7ua8SA4rM+ztigK9c8uegzuc0aVkktxTvukj0DZD472OwHnGQxlfNRogLlvr+Fq2hDn/7F+uKJiX1SVSARUy6/Ue9TePNvLS9jE6YXmcdFsyrPGE5HRWdKxFuAkedcz/FWzp53hNscXSKcfSHn8YDS0MCbiKEH7oBRhskBwNwQuV12M0GZcuExIFlT7mNZsX7dGXx4kCqjLm/wBysL3mRG043pGyhz4V/h1vh0/Ct0ovzTdsQMA7JHNa4PVQajpJx5Bx2Wm+PD1pvFD9UYLYp6Ir7XEt0kqb2YHwZjw7V/WTEgJL7uil5s+h01XygrfMCouN4gQu7JrEFY5mw6d4uFIdrc8toFi6cahbpwSYEcnPPm1gNUlfwAB4OrBXCdTgnnNhb0T1qfRY2S62th4nnLHH3bM1wOK/T8gx9j4cv3skWxFbr3OVf7mpWsaDlmxZdfbneZvPmmgzxX8hPbBGFTkOdiZP+xrw0YdB85J/WIeXmBcMe+vX6c6DlBGwek7m6BAj8oqlbRUYU8dpx+uV6Bq9L+YogzxLSJWbJ6PECwdQgOyQc+Vuz/GQ/PGrTFl711zFeX2leZepqI8Lm8L+dshhJNeC0iWpkj9wuWaTZe9uxqCCzBOygu6QZHYf3Ky6vTTbYRMnSjGzfsx3Nk8vNVuuFLIJwe5NGbjKARAKFoBz0x9zv48C7xBr9tHFDaJnneDZBiPgatJ4AnNtohVYeRFdEYJIbnMjh8uTM8gfBsHBll90I5A5RlFKXqXiif4vynZF6/LEKqZrdavNyFvopvX/ECEELXzcjF/yaYisFJc3MCD1mlGvZ6FV0HOgSZWFhkY5WP3XGlzQdIpcxxtrMQ1MBJPmG3Xrr015JQA+6ysETXjmdEop67Q1FdhSors53fFWifR0lAXC4qyA8jvl5Cn4BXaOD2DF/+uccwJOWYm8yQYpo7xYEeaVCNdZGs4so+2hHQaqx8U5WT81l03ulg8LqROBysgFEfAFO1H9E4dspUz6BiBA3uQNbMMYu561btsMkq+LUieGjoJlVei9rEV7CT7d1yqNLH2//9tnJCUwmLRcDL7mwRO3JFcEfK7b7/22ssHBqRz6rNLa4iWqF02BwoQOGRq32PehYjDp8D9tYM+VZeL24JH8v3rsXxUDJgNQCEmfy4oqWwhPy6FphfhNIr5e7eZ4EGBXVlfbuopoH+SgHhcMtHct1xP6uXQ5d+Fu7tEIyJyr7T6Kr3bsboT5OYkRUwoUlxwTG2o/Ajg4gnU9I2/LU/YlU27tl3ZqkSpy8fHiOeaNNc6FMQHNcZ4FQ8j9oViXKe3mbqjoy1P3ErqUsprRW6rwCTzg7AL9lnWXpgvzactwzVV58XMGrfjct4kI6lJzgcNA2pHniaJmZRDVCxn1HV/LWb9jsJxYFtKYPfI8J5AXieENTKZwXBFFrYkc5z4uk8+B70pIeT/dCt5mkK64AKMw8gqbv3fBz82mQ5MxtoBQC1JTc/ftv/bcj4cafL2A6typsTlV69JjmHn2d6xu8KZQ+JQFeYoitdQhUlZjvGBx4IPYjFszzZI11dcO27KEFVcOAl34JB6eOMUMl0svojRyWH5z2jLx1gy/iTtDZN6o7/pt2CVuDIJZWQjfsFqzhNTjEy+URSQvyN3I+Y+7AIAZMzT9eS3DWgeqcV6ClwMue3gLEvKMzibK6jikeXNbc0rXRRjOdFTal+DRDt9CV5Y22Rr8qDmILhFcGVNysY16lfRN41rNOT0eroayhsJl4ePYk1XhqtediU6gHI5SUvJJ+jIMwFj0GUs0MTDSReVVij5Gb7VKf94nPsXNfA+EtA325yVqA4Bmf/86BQkriUlGZF862ZcayaVh1mDhsRbNw/kHfYDdBXtXTkW7PxjuqosdQ2x61jjGEkD5XD5NSaYQ2MR4zpGdf84uH/ddSECuNbh5bm5coT4c6P2V8FRorJ/pr/HwiqAD11SA6OPhyDMYubbRSX2ENmtFbJOB9VpPbh2sFIJV3kIVQyV2U2q7Ui2AHmFwqRwMDswHzAHBgUrDgMCGgQUaiLcjagH49pKflR7OyBwt8MATiEEFD0ET7G+yzMbFl1u+WDzVT2akca5AgIH0A=="

class IntentViewController: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding, UITextFieldDelegate {
    var completionHandler:
    ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let togglePasswordButton = UIButton(type: .system)
    private var isPasswordVisible = false
    
    private let containerView = UIView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    
    private let loginButton = UIButton(type: .system)
    private let errorLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var gradientLayer: CAGradientLayer?
    private let authenticateButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        WalletAuthManager.shared.saveIdentity(identity_value)
        
        // UI Setup
        setupUI()
        
        // Auto-trigger biometric auth on load (optional)
        // authenticateUser()
    }
    
    // MARK: - Configure UI
    
    private func setupUI() {
        
        view.backgroundColor = .white
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 14
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.06
        containerView.layer.shadowOffset = CGSize(width: 0, height: 6)
        containerView.layer.shadowRadius = 12
        view.addSubview(containerView)
        
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.image = UIImage(named: "kfh_logo")
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Welcome Back"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        usernameField.placeholder = "Username"
        usernameField.keyboardType = .asciiCapable
        usernameField.borderStyle = .none
        usernameField.backgroundColor = .white
        usernameField.textColor = .black
        usernameField.tintColor = .black
        usernameField.keyboardType = .asciiCapable
        usernameField.layer.cornerRadius = 8
        usernameField.layer.borderWidth = 1
        usernameField.layer.borderColor = UIColor.systemGray3.cgColor
        
        usernameField.attributedPlaceholder = NSAttributedString(
            string: "Username",
            attributes: [
                .foregroundColor: UIColor.systemGray2
            ]
        )
        
        let usernameLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        usernameField.leftView = usernameLeftPaddingView
        usernameField.leftViewMode = .always
        
        let usernameRightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        usernameField.rightView = usernameRightPaddingView
        usernameField.rightViewMode = .always
        
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.placeholder = "Password"
        passwordField.isSecureTextEntry = true
        passwordField.borderStyle = .none
        passwordField.backgroundColor = .white
        passwordField.textColor = .black
        passwordField.tintColor = .black
        passwordField.layer.cornerRadius = 8
        passwordField.layer.borderWidth = 1
        passwordField.layer.borderColor = UIColor.systemGray3.cgColor
        
        passwordField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [
                .foregroundColor: UIColor.systemGray2
            ]
        )
        
        let passwordLeftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        passwordField.leftView = passwordLeftPaddingView
        passwordField.leftViewMode = .always
        
        let passwordRightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        passwordField.rightView = passwordRightPaddingView
        passwordField.rightViewMode = .always
        
        let eyeImage = UIImage(
            systemName: "eye",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        )
        
        togglePasswordButton.setImage(eyeImage, for: .normal)
        togglePasswordButton.tintColor = UIColor.systemGray2
        togglePasswordButton.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
        
        togglePasswordButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        
        let eyeContainerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 44))
        togglePasswordButton.center = CGPoint(x: 35, y: 22)
        eyeContainerView.addSubview(togglePasswordButton)
        
        passwordField.rightView = eyeContainerView
        passwordField.rightViewMode = .always
        
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 13)
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("LOGIN", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        
        containerView.addSubview(logoImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(usernameField)
        containerView.addSubview(passwordField)
        containerView.addSubview(errorLabel)
        containerView.addSubview(loginButton)
        containerView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            logoImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            logoImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            usernameField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            usernameField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            usernameField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            usernameField.heightAnchor.constraint(equalToConstant: 44),
            
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: usernameField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: usernameField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            
            errorLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),
            errorLabel.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),
            
            loginButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            loginButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            loginButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            activityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            activityIndicator.trailingAnchor.constraint(equalTo: loginButton.trailingAnchor, constant: -12)
        ])
        
        applyLoginGradient()
        
        // Setup keyboard dismissal and accessory Done button
        setupKeyboardDismissal()
    }
    
    private func applyLoginGradient() {
        let buttonColor = UIColor(red: 35/255, green: 96/255, blue: 80/255, alpha: 1.0)
        loginButton.backgroundColor = buttonColor
        loginButton.layer.cornerRadius = 10
    }
    
    private func setupKeyboardDismissal() {
        usernameField.delegate = self
        passwordField.delegate = self
        
        usernameField.returnKeyType = .next
        passwordField.returnKeyType = .done
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.items = [flex, done]
        
        usernameField.inputAccessoryView = toolbar
        passwordField.inputAccessoryView = toolbar
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc private func togglePasswordVisibility() {
        isPasswordVisible.toggle()
        passwordField.isSecureTextEntry = !isPasswordVisible
        togglePasswordButton.setImage(
            UIImage(systemName: isPasswordVisible ? "eye.slash" : "eye"),
            for: .normal
        )
    }
    
    @objc private func loginTapped() {
        
        errorLabel.isHidden = true
        
//        guard let username = usernameField.text, !username.isEmpty else {
//            showError("Username is required")
//            return
//        }
//
//        guard let password = passwordField.text, !password.isEmpty else {
//            showError("Password is required")
//            return
//        }
        
        loginButton.isEnabled = false
        activityIndicator.startAnimating()
        
        authenticate(username: self.getEntityDetails().username, password: self.getEntityDetails().password)
    }
    
    private func authenticate(username: String, password: String) {
        
        WalletAuthManager.shared.clearToken()
        WalletAuthManager.shared.clearSessionToken()
        
        callWalletLoginAPI(username: username, password: password) { result in
            
            switch result {
                
            case .success(let sessionToken):
                os_log("Session Token saved here: \(sessionToken)")
                
                DispatchQueue.main.async {
                    self.completionHandler?(.authorized)
                }
                
            case .failure(let error):
                os_log("Login Error: \(error.localizedDescription)")
            }
        }
    }
}

// call all token related APIs
extension IntentViewController {
    
    func callWalletLoginAPI(
        username: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void) {
            
        getValidToken { token in
                
            guard let token = token else {
                os_log("No valid token available")
                completion(.failure(NSError(domain: "TokenError", code: 0)))
                return
            }
                
            let encryptedPassword = self.encryptAES(
                tranData: password,
                key: encryptionKey
            )
                
            let txnRef = self.generateTxnRef()
                    
            let xmlString = """
                <AUB_MESSAGE>
                    <REQUEST_MESSAGE>
                        <RequestHeader>
                            <MsgType>Request</MsgType>
                            <ReqID>MB_WALLET</ReqID>
                            <ChSysID>MB_WALLET_EXT</ChSysID>
                            <FuncID>WALLET_LOGIN_AUTH</FuncID>
                            <UserID/>
                            <TxnRef>\(txnRef)</TxnRef>
                            <CorrTxnRef />
                            <TxnDate>\(self.getTxnDate())</TxnDate>
                            <CustGrpID/>
                            <CustNIN></CustNIN>
                            <EntID>\(self.getEntityDetails().entity)</EntID>
                            <SysID/>
                            <CustID/>
                            <ProcessEntID/>
                            <OrigEntID>\(self.getEntityDetails().entity)</OrigEntID>
                            <TxnStatus>Y</TxnStatus>
                            <SessLang>E</SessLang>
                            <VerNo>0001</VerNo>
                            <SessToken>123456789</SessToken>
                            <BypassOds>Y</BypassOds>
                        </RequestHeader>
                        <RequestBody>
                            <WALLET_LOGIN_AUTH_RQ>
                                <entityId>\(self.getEntityDetails().entity)</entityId>
                                <deviceId>\(self.getDeviceId())</deviceId>
                                <ipAddress>\(self.getIPAddress())</ipAddress>
                                <userName>\(username)</userName>
                                <password>\(encryptedPassword ?? "")</password>
                            </WALLET_LOGIN_AUTH_RQ>
                        </RequestBody>
                    </REQUEST_MESSAGE>
                </AUB_MESSAGE>
                """
                    
                let signedRequest = SignedRequestGenerator.createSignedRequest(
                    xmlRequest: xmlString,
                    token: self.getEntityDetails().signedRequestToken
                )
                    
                let postData = """
                    <s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
                        <SOAP-ENV:Header/>
                        <s:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
                            <getResponse xmlns="http://middleware.webservice.aub.com">
                                <request>
                                    <![CDATA[\(signedRequest ?? "")]]>
                                </request>
                            </getResponse>
                        </s:Body>
                    </s:Envelope>
                    """
                    
                os_log("callWalletLoginAPI post data = \(postData)")
                    
                let consumer = HTTPSConsumer()
                    
                consumer.consumePOST(
                    url: "\(BASE_URL)/kfh/uat/eiphandlerservice/invoke/wallet_login_auth",
                    postData: postData,
                    headers: [
                        "Authorization": token,
                        "TxnRef": txnRef,
                        "X-IBM-Client-Id": self.getEntityDetails().clientID
                    ],
                    contentType: "application/xml"
                ) { result in
                        
                    switch result {
                    
                    case .success(let response):
                        os_log("callWalletLoginAPI API Success: \(response)")
                            
                        if let sessionToken = self.extractSessionToken(from: response) {
                            WalletAuthManager.shared.saveSessionToken(sessionToken)
                            completion(.success(sessionToken))
                        } else {
                            completion(.failure(NSError(domain: "SessionTokenMissing", code: 0)))
                        }
                            
                    case .failure(let error):
                        os_log("callWalletLoginAPI API Error: \(error)")
                        completion(.failure(error))
                    }
                }
        }
    }
}

// token API and check valid token
extension IntentViewController {

    func getValidToken(completion: @escaping (String?) -> Void) {

        // If valid stored token exists → use it
        if let token = WalletAuthManager.shared.getStoredValidToken() {
            os_log("token saved = \(token)")
            completion(token)
            return
        }

        // Otherwise fetch new token
        getTokenAPI { newToken in
            os_log("new toen refresh = \(newToken ?? "no new token")")
            completion(newToken)
        }
    }
    
    func getTokenAPI(completion: @escaping (String?) -> Void) {

        let consumer = HTTPSConsumer()

        consumer.consumeGET(
            url: "\(BASE_URL)/kfh/uat/auth/token",
            headers: [
                "X-IBM-Client-Id": getEntityDetails().clientID,
                "X-IBM-Client-Secret": getEntityDetails().clientSecret,
                "TxnRef": generateTxnRef()
            ]
        ) { result in

            switch result {

            case .success(let responseString):

                guard let data = responseString.data(using: .utf8) else {
                    completion(nil)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
                    WalletAuthManager.shared.saveToken(decoded)

                    completion(decoded.token)
                } catch {
                    os_log("Decoding Error = \(error)")
                    completion(nil)
                }

            case .failure(let error):
                os_log("Token API Error: \(error)")
                completion(nil)
            }
        }
    }
}

enum AUBEntity: String {
    case AUBBH
    case AUBUK
}

struct AUBCredentials {
    let entity: String
    let clientID: String
    let clientSecret: String
    let signedRequestToken: String
    let username: String
    let password: String
}

struct TokenResponse: Codable {
    let token: String
    let expires_in: String
    let token_type: String
}

struct Card {
    var cardId: String = ""
    var maskedCardNumber: String = ""
    var artUrl: String?
    var cardTitle: String = ""
    var holderName: String = ""
}

// for getting entity type like BHARRIN or UK
extension IntentViewController {
    
    func getEntityDetails() -> AUBCredentials {
        let credentials = getCredentials(for: entity)
        return credentials
    }

    func getCredentials(for entity: AUBEntity) -> AUBCredentials {
        
        switch entity {
            
        case .AUBBH:
            return AUBCredentials(
                entity: "AUBBH",
                clientID: "9ad769f1dabad84ba943f561616c0faf",
                clientSecret: "702e32b2b2962fd081c97e9f1a801550",
                signedRequestToken: "S2lxSElGZ3VVdnFWSmFqRG9yT2RYbzNzSXRvdXNJMEM",
                username: "Testuser1",
                password: "Passw0rd"
            )
            
        case .AUBUK:
            return AUBCredentials(
                entity: "AUBUK",
                clientID: "f6a7e302b3448a7104d7e2f758dd8760",
                clientSecret: "726fbd8dcad97a53e5bcd4ae0ea60064",
                signedRequestToken: "a0FpbUxWMkhOTnRBenFMakozdXNjRjh0V1BGR1p4TEk",
                username: "ukadventtest112",
                password: "Passw0rd"
            )
        }
    }
}

// all common functions
extension IntentViewController {
    
    func generateTxnRef() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set Bahrain Timezone
        formatter.timeZone = TimeZone(identifier: "Asia/Bahrain")
        
        let dateTime = formatter.string(from: Date())
        
        // Generate 4 random digits
        let randomNumber = String(format: "%04d", Int.random(in: 0...9999))

        return "RI\(dateTime)\(randomNumber)"
    }

    func getTxnDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Set Bahrain timezone (UTC+3)
        formatter.timeZone = TimeZone(identifier: "Asia/Bahrain")
        
        return formatter.string(from: Date())
    }

    func getDeviceId() -> String {
        let deviceid = UIDevice.current.identifierForVendor?.uuidString ?? "UNKNOWN_DEVICE_ID"
        return deviceid
    }

    func getIPAddress() -> String {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                let interface = ptr!.pointee

                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    let name = String(cString: interface.ifa_name)

                    // Wi-Fi: en0 | Cellular: pdp_ip0
                    if name == "en0" || name == "pdp_ip0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(
                            interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        )
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address ?? "0.0.0.0"
    }
    
    func encryptAES(tranData: String, key: String) -> String? {
        
        guard let data = tranData.data(using: .utf8),
              let keyData = key.data(using: .utf8),
              let ivData = ivString.data(using: .utf8) else {
            return nil
        }
     
        let outputLength = data.count + kCCBlockSizeAES128
        var outputData = Data(count: outputLength)
     
        var bytesEncrypted = 0
     
        let status = outputData.withUnsafeMutableBytes { outputBytes in
            data.withUnsafeBytes { dataBytes in
                keyData.withUnsafeBytes { keyBytes in
                    ivData.withUnsafeBytes { ivBytes in
                        CCCrypt(
                            CCOperation(kCCEncrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(kCCOptionPKCS7Padding),
                            keyBytes.baseAddress,
                            keyData.count, // 16=AES128, 32=AES256
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            data.count,
                            outputBytes.baseAddress,
                            outputLength,
                            &bytesEncrypted
                        )
                    }
                }
            }
        }
     
        guard status == kCCSuccess else {
            os_log("Encryption failed")
            return nil
        }
     
        outputData.removeSubrange(bytesEncrypted..<outputData.count)
     
        // Swift AES output → Base64
        let base64String = outputData.base64EncodedString()
     
        // Convert Base64 → Hex (same as CryptoJS flow)
        guard let base64Data = Data(base64Encoded: base64String) else { return nil }
     
        let hexString = base64Data.map { String(format: "%02X", $0) }.joined()
        return hexString
    }
}

// for getting data from all XML API responses
extension IntentViewController {
    
    func extractSessionToken(from soapResponse: String) -> String? {
        
        // 1️⃣ Extract CDATA
        guard let cdataStart = soapResponse.range(of: "<![CDATA["),
              let cdataEnd = soapResponse.range(of: "]]>") else {
            return nil
        }
        
        let innerXML = String(soapResponse[cdataStart.upperBound..<cdataEnd.lowerBound])
        
        // 2️⃣ Extract <sessionToken> using simple range search (fast & clean)
        guard let start = innerXML.range(of: "<sessionToken>"),
              let end = innerXML.range(of: "</sessionToken>") else {
            return nil
        }
        
        let token = innerXML[start.upperBound..<end.lowerBound]
        return String(token)
    }
}

final class SignedRequestGenerator {

    /// Equivalent to MssCreate_SignedRequest
    static func createSignedRequest(
        xmlRequest: String,
        token: String
    ) -> String? {
        
        // 1️⃣ Normalize XML (remove formatting / line breaks)
        guard let oneLineXML = normalizeXML(xmlRequest) else {
            return nil
        }

        // 2️⃣ Clear SessToken value
        let clearedXML = oneLineXML.replacingOccurrences(
            of: "<SessToken.*?>.*?</SessToken>",
            with: "<SessToken></SessToken>",
            options: .regularExpression
        )

        // 3️⃣ Generate signature
        guard let signedToken = generateHash(
            maskedToken: token,
            request: clearedXML
        ) else {
            return nil
        }

        // 4️⃣ Inject signature back into XML
        let signedRequest = clearedXML.replacingOccurrences(
            of: "<SessToken></SessToken>",
            with: "<SessToken>\(signedToken)</SessToken>"
        )

        return signedRequest
    }
    
    private static func normalizeXML(_ xml: String) -> String? {
        let xmlData = xml.data(using: .utf8)
        let parser = XMLParser(data: xmlData ?? Data())
        parser.shouldProcessNamespaces = false
        parser.shouldResolveExternalEntities = false
        parser.shouldReportNamespacePrefixes = false

        // Simply remove newlines & extra spaces
        return xml
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "  ", with: "")
    }

    /// Equivalent to GenerateHash
    private static func generateHash(
        maskedToken: String,
        request: String
    ) -> String? {
        
        guard let keyData = decodeBase64(maskedToken),
              let messageData = request.data(using: .utf8) else {
            return nil
        }

        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(
            for: messageData,
            using: key
        )

        return Data(signature).base64EncodedString()
    }
    
    private static func decodeBase64(_ base64: String) -> Data? {
        var padded = base64
        let remainder = base64.count % 4
        if remainder > 0 {
            padded += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: padded)
    }
}

final class HTTPSessionDelegate: NSObject, URLSessionDelegate {

    private let identity: SecIdentity?

    init(identity: SecIdentity?) {
        self.identity = identity
    }

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate,
           let identity = identity {

            let credential = URLCredential(
                identity: identity,
                certificates: nil,
                persistence: .forSession
            )

            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

final class HTTPSConsumer {

    private func createSession(identity: SecIdentity?) -> URLSession {

            let config = URLSessionConfiguration.default

            // iOS / macOS allow TLS 1.2+ only
            if #available(iOS 13.0, macOS 10.15, *) {
                config.tlsMinimumSupportedProtocolVersion = .TLSv12
            }

            let delegate = HTTPSessionDelegate(identity: identity)
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        }

        func consumeGET(
            url: String,
            headers: [String: String] = [:],
            contentType: String = "application/x-www-form-urlencoded",
            completion: @escaping (Result<String, Error>) -> Void
        ) {

            guard let identity = getIdentityFromData() else {
                completion(.failure(NSError(domain: "IdentityNotFound", code: -1)))
                return
            }

            guard let requestURL = URL(string: url) else {
                completion(.failure(NSError(domain: "InvalidURL", code: -1)))
                return
            }

            var request = URLRequest(url: requestURL)
            request.httpMethod = "GET"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }

            let session = createSession(identity: identity)

            session.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let response = String(decoding: data ?? Data(), as: UTF8.self)
                    completion(.success(response))
                }
            }.resume()
        }

        func consumePOST(
            url: String,
            postData: String,
            headers: [String: String] = [:],
            contentType: String = "application/x-www-form-urlencoded",
            completion: @escaping (Result<String, Error>) -> Void
        ) {
            
            guard let identity = getIdentityFromData() else {
                completion(.failure(NSError(domain: "IdentityNotFound", code: -1)))
                return
            }

            guard let requestURL = URL(string: url) else {
                completion(.failure(NSError(domain: "InvalidURL", code: -1)))
                return
            }

            var request = URLRequest(url: requestURL)
            request.httpMethod = "POST"
            request.httpBody = postData.data(using: .utf8)
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")

            headers.forEach {
                request.setValue($0.value, forHTTPHeaderField: $0.key)
            }

            let session = createSession(identity: identity)

            session.dataTask(with: request) { data, _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let response = String(decoding: data ?? Data(), as: UTF8.self)
                    completion(.success(response))
                }
            }.resume()
        }
        
        func getIdentityFromData() -> SecIdentity? {
            
            guard let content = WalletAuthManager.shared.getIdentityContent() else {
                os_log("no content from keychain")
                return nil
            }
            
            os_log("identity data from keychain= \(content.count)")
            
            // ✅ Base64 → Data
            guard let pfxData = Data(base64Encoded: content) else {
                print("❌ Invalid Base64")
                return nil
            }
            
            let options: [String: Any] = [
                kSecImportExportPassphrase as String: certPassword
            ]

            var items: CFArray?

            let status = SecPKCS12Import(pfxData as CFData, options as CFDictionary, &items)

            guard status == errSecSuccess else {
                print("❌ PKCS12 import failed:", status)
                return nil
            }

            guard let array = items as? [[String: Any]],
                let first = array.first,
                let identity = first[kSecImportItemIdentity as String] else {
                
                print("❌ Identity extraction failed")
                return nil
            }
            
            print("identity extracted = ", identity)

            return (identity as! SecIdentity)
        }
}

// for auth token save and clear user defaults related to auth token
class WalletAuthManager {

    static let shared = WalletAuthManager()

    private var tokenKey: String { "AUTH_TOKEN" }
    private var expiryKey: String { "AUTH_TOKEN_EXPIRY" }
    private var sessionTokenKey: String { "SESSION_TOKEN" }
    private var identityContentKey: String { "IDENTITY_CONTENT_TOKEN" }

    func saveToken(_ response: TokenResponse) {

        let expiresIn = TimeInterval(response.expires_in) ?? 3600

        let expiryDate = Date().addingTimeInterval(expiresIn - 300)

        KeychainHelper.save(key: tokenKey, value: response.token)
        KeychainHelper.save(key: expiryKey, value: "\(expiryDate.timeIntervalSince1970)")
    }

    func getStoredValidToken() -> String? {

        guard let token = KeychainHelper.read(key: tokenKey),
              let expiryString = KeychainHelper.read(key: expiryKey),
              let expiryTime = Double(expiryString) else {
            return nil
        }

        if Date().timeIntervalSince1970 < expiryTime {
            return token
        } else {
            clearToken()
            return nil
        }
    }

    func clearToken() {
        KeychainHelper.delete(key: tokenKey)
        KeychainHelper.delete(key: expiryKey)
    }

    func saveSessionToken(_ token: String) {
        KeychainHelper.save(key: sessionTokenKey, value: token)
    }

    func getSessionToken() -> String? {
        return KeychainHelper.read(key: sessionTokenKey)
    }

    func clearSessionToken() {
        KeychainHelper.delete(key: sessionTokenKey)
    }
    
    func saveIdentity(_ content: String) {
        KeychainHelper.save(key: identityContentKey, value: content)
    }
        
    func clearIdentity() {
        KeychainHelper.delete(key: identityContentKey)
    }
        
    func getIdentityContent() -> String? {
        return KeychainHelper.read(key: identityContentKey)
    }
}

class KeychainHelper {

    static func save(key: String, value: String) {
        let data = value.data(using: .utf8)!

        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccessGroup as String: appGroupID
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            os_log("Keychain save error: \(status)")
        }
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessGroup as String: appGroupID
        ]

        var dataTypeRef: AnyObject?

        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }

        os_log("Keychain read error: \(status)")
        return nil
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: appGroupID
        ]

        SecItemDelete(query as CFDictionary)
    }
}


