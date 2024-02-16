//
//  WebExtensionMetadataView.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Cocoa

final class WebExtensionMetadataView: NSView {
    var manifest: WebExtensionManifest? {
        didSet {
            if let manifest {
                nameLabel?.stringValue = manifest.name
                authorLabel?.stringValue = manifest.author
                descriptionLabel?.stringValue = ""
            }
        }
    }

    private var nameLabel: NSTextField?
    private var authorLabel: NSTextField?
    private var descriptionLabel: NSTextField?

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupViews()
    }

    init(frame: NSRect, manifest: WebExtensionManifest) {
        super.init(frame: frame)
        self.manifest = manifest
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        let nameLabel = NSTextField.create(label: manifest?.name ?? "")
        let authorLabel = NSTextField.create(label: manifest?.author ?? "")
        let descriptionLabel = NSTextField.create(label: "")
        // etc...

        for item in [nameLabel, authorLabel, descriptionLabel] {
            addSubview(item)
            item.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            nameLabel.heightAnchor.constraint(equalToConstant: 16),
        ])

        NSLayoutConstraint.activate([
            authorLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            authorLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 16),
            authorLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            authorLabel.heightAnchor.constraint(equalToConstant: 16),
        ])

        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 144),
        ])

        self.nameLabel = nameLabel
        self.authorLabel = authorLabel
        self.descriptionLabel = descriptionLabel
    }
}

extension NSTextField {
    static func create(label: String) -> NSTextField {
        let textField = NSTextField()
        textField.isEditable = false
        textField.isBordered = false
        textField.isSelectable = true
        textField.stringValue = label
        textField.backgroundColor = .clear
        textField.textColor = .labelColor
        return textField
    }
}
