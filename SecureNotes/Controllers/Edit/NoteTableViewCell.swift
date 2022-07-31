//
//  NoteTableViewCell.swift
//  SecureNotes
//
//

import UIKit

class NoteTableViewCell: UITableViewCell {
    private let titleLabel = UILabel()
    private let lastModifiedLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }

    private func layout() {
        let margin = 12.0
        let views = [titleLabel, lastModifiedLabel]
        titleLabel.font = UIFont.defaultTitleFont()
        lastModifiedLabel.font = UIFont.defaultSubTitleFont()
        lastModifiedLabel.textColor = .gray
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        let stackView = UIStackView.init(arrangedSubviews: views)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = margin
        stackView.alignment = .leading
        stackView.distribution = .fill
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: margin),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2*margin),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -margin)
        ])
    }

    func configure(note: Note) {
        titleLabel.text = note.title
        lastModifiedLabel.text = note.lastModified.timeString()
    }
}
