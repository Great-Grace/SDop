import ManagedSettings
import ManagedSettingsUI
import UIKit

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    struct SDopColors {
        static let primary = UIColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0) // #FF6B35
        static let background = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        static let textDark = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        static let textLight = UIColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
    }

    func configuration(shielding application: Application) -> ShieldConfiguration {
        let title = ShieldConfiguration.Label(
            text: "집중 모드 실행 중 📖",
            color: SDopColors.textDark
        )
        let subtitle = ShieldConfiguration.Label(
            text: "지금은 독서에 집중할 시간이에요!",
            color: SDopColors.textLight
        )
        let primaryButton = ShieldConfiguration.Button(
            label: "책 읽고 해제하기",
            color: SDopColors.primary
        )
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: SDopColors.background,
            icon: UIImage(systemName: "book.closed.fill"),
            title: title,
            subtitle: subtitle,
            primaryButton: primaryButton,
            primaryButtonBackgroundColor: SDopColors.primary
        )
    }

    func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let title = ShieldConfiguration.Label(
            text: "앱 사용 시간 초과 ⏰",
            color: SDopColors.textDark
        )
        let subtitle = ShieldConfiguration.Label(
            text: "정해진 시간이 지났어요.\n책을 읽으면 다시 사용할 수 있어요!",
            color: SDopColors.textLight
        )
        let primaryButton = ShieldConfiguration.Button(
            label: "책 읽고 해제하기",
            color: SDopColors.primary
        )
        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: SDopColors.background,
            icon: UIImage(systemName: "hourglass.tophalf.filled"),
            title: title,
            subtitle: subtitle,
            primaryButton: primaryButton,
            primaryButtonBackgroundColor: SDopColors.primary
        )
    }
}
