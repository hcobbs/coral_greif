//
//  MainMenuViewController.swift
//  Coral Greif
//
//  Copyright (c) 2024 T. Hunter Cobbs. All Rights Reserved.
//

import UIKit

/// Delegate for main menu events.
protocol MainMenuDelegate: AnyObject {
    func mainMenuDidSelectNewGame(_ viewController: MainMenuViewController, difficulty: AIDifficulty)
    func mainMenuDidSelectSettings(_ viewController: MainMenuViewController)
}

/// The main menu screen shown when the app launches.
final class MainMenuViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: MainMenuDelegate?

    // MARK: - UI Elements

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "CORAL GREIF"
        label.applyTitleStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Pacific Theater, 1942"
        label.applyBodyStyle()
        label.textColor = AppTheme.Colors.brassGold
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var difficultyLabel: UILabel = {
        let label = UILabel()
        label.text = "Select Your Opponent"
        label.applyHeadingStyle()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.text = "v1.0"
        label.font = AppTheme.Fonts.caption()
        label.textColor = AppTheme.Colors.textSecondary
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDifficultyButtons()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = AppTheme.Colors.oceanDeep

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(difficultyLabel)
        view.addSubview(buttonStack)
        view.addSubview(versionLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            difficultyLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            difficultyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            buttonStack.topAnchor.constraint(equalTo: difficultyLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            versionLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            versionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupDifficultyButtons() {
        for difficulty in AIDifficulty.allCases {
            let button = createDifficultyButton(for: difficulty)
            buttonStack.addArrangedSubview(button)
        }
    }

    private func createDifficultyButton(for difficulty: AIDifficulty) -> UIView {
        let container = UIView()
        container.applyCardStyle()
        container.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = difficulty.displayName
        titleLabel.font = AppTheme.Fonts.heading()
        titleLabel.textColor = AppTheme.Colors.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let descLabel = UILabel()
        descLabel.text = difficulty.description
        descLabel.font = AppTheme.Fonts.caption()
        descLabel.textColor = AppTheme.Colors.textSecondary
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        let rankIcon = createRankIcon(for: difficulty)
        rankIcon.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(rankIcon)
        container.addSubview(titleLabel)
        container.addSubview(descLabel)

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            rankIcon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            rankIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            rankIcon.widthAnchor.constraint(equalToConstant: 40),
            rankIcon.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.leadingAnchor.constraint(equalTo: rankIcon.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),

            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            descLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        // Add tap gesture
        let tap = UITapGestureRecognizer(target: self, action: #selector(difficultyTapped(_:)))
        container.addGestureRecognizer(tap)
        container.tag = AIDifficulty.allCases.firstIndex(of: difficulty) ?? 0
        container.isUserInteractionEnabled = true

        return container
    }

    private func createRankIcon(for difficulty: AIDifficulty) -> UIView {
        let container = UIView()
        container.backgroundColor = AppTheme.Colors.brassGold
        container.layer.cornerRadius = 20

        let label = UILabel()
        label.textAlignment = .center
        label.textColor = AppTheme.Colors.oceanDeep
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false

        switch difficulty {
        case .ensign:
            label.text = "E"
        case .commander:
            label.text = "C"
        case .admiral:
            label.text = "A"
        }

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        return container
    }

    // MARK: - Actions

    @objc private func difficultyTapped(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        let difficulty = AIDifficulty.allCases[view.tag]

        // Animate tap
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1) {
                view.transform = .identity
            }
        })

        delegate?.mainMenuDidSelectNewGame(self, difficulty: difficulty)
    }
}
