//
//  EditNoteViewController.swift
//  SecureNotes
//
//

import UIKit
import CryptoSwift

class EditNoteViewController: UIViewController {
    var note: Note!
    private let scrollView = UIScrollView()
    private let titleTextView = UITextView()
    private let createdDateLabel = UILabel()
    private let noteBodyTextView = UITextView()
    weak var delegate: SaveNoteDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.tintColor = UIColor.defaultColor()
        layout()
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if noteBodyTextView.text.isEmpty {
            noteBodyTextView.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if note.title != titleTextView.text ||  note.content != noteBodyTextView.text {
            note.hasBeenModified = true
            note.title = titleTextView.text
            note.content = noteBodyTextView.text
            note.lastModified = Date()
        }
        delegate?.saveNote(note)
    }
    
    func setup() {
        titleTextView.text = note.title
        titleTextView.font = UIFont.defaultTitleFont()
        
        createdDateLabel.text = note.created.timeString()
        createdDateLabel.font = UIFont.defaultSubTitleFont()
        
        noteBodyTextView.text = note.content
        noteBodyTextView.font = UIFont.defaultBodyFont()
    }
}

extension EditNoteViewController {
    func layout() {
        view.backgroundColor = .white

        let margin = 16.0
        let maxBodyHeight = 500.0
        // set up scroll view and content view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.contentInset = UIEdgeInsets(top: 2*margin, left: 0, bottom: 0, right: 0)
        view.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.rightAnchor.constraint(equalTo: view.rightAnchor),
            scrollView.leftAnchor.constraint(equalTo: view.leftAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.rightAnchor.constraint(equalTo: scrollView.rightAnchor),
            contentView.leftAnchor.constraint(equalTo: scrollView.leftAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        // Set up layout for title, date created and note body
        titleTextView.translatesAutoresizingMaskIntoConstraints = false
        titleTextView.isScrollEnabled = false
        contentView.addSubview(titleTextView)
        
        createdDateLabel.translatesAutoresizingMaskIntoConstraints = false
        createdDateLabel.textColor = .gray
        contentView.addSubview(createdDateLabel)
        
        noteBodyTextView.font = UIFont.preferredFont(forTextStyle: .body)
        noteBodyTextView.isScrollEnabled = false
        noteBodyTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(noteBodyTextView)
        
        NSLayoutConstraint.activate([
            titleTextView.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleTextView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: margin),
            titleTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -margin),
            
            createdDateLabel.topAnchor.constraint(equalTo: titleTextView.bottomAnchor, constant: margin/2),
            createdDateLabel.leftAnchor.constraint(equalTo: titleTextView.leftAnchor),
            createdDateLabel.rightAnchor.constraint(equalTo: createdDateLabel.rightAnchor),
            
            noteBodyTextView.topAnchor.constraint(equalTo: createdDateLabel.bottomAnchor, constant: margin),
            noteBodyTextView.leftAnchor.constraint(equalTo: titleTextView.leftAnchor),
            noteBodyTextView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: margin),
            noteBodyTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            noteBodyTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: maxBodyHeight)
        ])
    }
}
