//
//  ListNoteViewController.swift
//  SecureNotes
//
//

import UIKit

protocol SaveNoteDelegate: AnyObject {
    func saveNote(_ note: Note)
}

class ListNoteViewController: UIViewController, SaveNoteDelegate {
    private var tableView = UITableView()
    
    @NewestFirst var notes = [Note]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor:
                                                                            UIColor.defaultColor()]
        self.title = "Notes"
        setup()
        layout()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        notes.removeAll()
    }
    
    @objc func composeNoteButtonTapped() {
        let detailVC = EditNoteViewController()
        detailVC.note = Note()
        detailVC.delegate = self
        present(detailVC, animated: true)
    }
    
    func confirmDeleteNote(atIndex: Int) {
        let alertVC = UIAlertController(title: "Delete Note?",
                                        message: "Are you sure you want to delete this note? Click Delete to confirm.",
                                        preferredStyle: .alert)
        let deleteAction: UIAlertAction = UIAlertAction(title: "Delete", style: .default) { [weak self] _ in
            self?.deleteNote(atIndex: atIndex)
            self?.navigationController?.popViewController(animated: true)
        }
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertVC.addAction(deleteAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func deleteNote(atIndex: Int) {
        if let noteId = notes[atIndex].id {
            do {
                try NoteService.shared.deleteNote(nodeId: noteId)
                notes.remove(at: atIndex)
                tableView.reloadData()
            } catch {
                showAlert(error.localizedDescription)
            }
        }
    }
    
    func saveNote(_ note: Note) {
        do {
            if note.id != nil {
                if note.hasBeenModified {
                    // Save existing data
                    try NoteService.shared.updateNote(note)
                    // Remove old note in notes array
                    notes.removeAll { $0.id == note.id}
                    // Append the edited note
                    notes.append(note)
                    tableView.reloadData()
                } else {
                    // Do nothing
                }
            } else {
                // Insert a new note
                let noteId = try NoteService.shared.insertNote(note)
                var newNote = note
                newNote.id = noteId
                notes.append(newNote)
                tableView.reloadData()
            }
        } catch {
            showAlert(error.localizedDescription)
        }
    }
}

extension ListNoteViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell")
                as? NoteTableViewCell else { return UITableViewCell() }
        let item = notes[indexPath.row]
        cell.configure(note: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = notes[indexPath.row]
        let detailVC = EditNoteViewController()
        detailVC.note = item
        detailVC.delegate = self
        tableView.deselectRow(at: indexPath, animated: true)
        present(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, _) in
            self?.confirmDeleteNote(atIndex: indexPath.row)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension ListNoteViewController {
    func setup() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NoteTableViewCell.self, forCellReuseIdentifier: "NoteTableViewCell")
    }
    
    func layout() {
        view.backgroundColor = .white
        // Add compose button in navigation bar
        let compose = UIBarButtonItem(barButtonSystemItem: .compose,
                                      target: self, action: #selector(composeNoteButtonTapped))
        compose.tintColor = UIColor.defaultColor()
        navigationItem.rightBarButtonItems = [compose]
        // Layout table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .singleLine
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
}
