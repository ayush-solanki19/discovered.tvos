//
//  ShowCell.swift
//  discovered.tvos
//
//  Created by mac mini on 17/08/26.
//

import UIKit

class ShowCell: UICollectionViewCell {
    static let reuseIdentifier = "ShowCell"
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }

    private func setupLayout() {
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor(white: 0.14, alpha: 1)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        titleLabel.font = .systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -10),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            titleLabel.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    func configure(with item: ShowItem) {
        titleLabel.text = item.title
        if item.imageName.hasPrefix("http") {
            imageView.setImage(from: item.imageName)
        } else {
            imageView.image = UIImage(named: item.imageName) ?? UIImage(named: "hero_back")
        }
    }
    
    override var canBecomeFocused: Bool { true }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations({
            if self.isFocused {
                self.contentView.layer.borderWidth = 3.5
                self.contentView.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            } else {
                self.contentView.layer.borderWidth = 0
                self.contentView.layer.borderColor = UIColor.clear.cgColor
                self.transform = .identity
            }
        }, completion: nil)
    }
}

extension UIImageView {
    func setImage(from urlString: String?, placeholder: String = "hero_back") {
        self.image = UIImage(named: placeholder)
        
        guard let urlString = urlString, let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                self?.image = image
            }
        }.resume()
    }
}
