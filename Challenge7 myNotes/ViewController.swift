//  ViewController.swift
//  Challenge7 myNotes
//  Created by Ahmed Shaban on 01/09/2022.

import UIKit
class collectionController: UICollectionViewController {
    
    //MARK: Properties
    var notes = [Note]()
    
    //MARK: View
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.isHidden = true
        userLogin()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add Note", style: .plain, target: self, action: #selector(addNote))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        collectionView.addGestureRecognizer(longPress)
        
        let defaults = UserDefaults.standard
        if let savedNotes = defaults.object(forKey: "notes") as? Data {
            let jsonDecoder = JSONDecoder()
            do {
                notes = try jsonDecoder.decode([Note].self, from: savedNotes)
            } catch {
                print("Failed to Load")
            }
        }
    }
    
    
    //MARK: Methods
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: touchPoint) {
                let note = notes[indexPath.item]
                let ac = UIAlertController(title: "Options", message: nil, preferredStyle: .alert)
                ac.addTextField()
                ac.textFields?[0].text = note.title
                ac.addAction(UIAlertAction(title: "delete", style: .cancel) {
                    [weak self] _ in
                    self?.notes.remove(at: indexPath.item)
                    self?.save()
                    self?.collectionView.reloadData()
                })
                ac.addAction(UIAlertAction(title: "rename", style: .default) { [weak self, weak ac] _ in
                    guard let newNote = ac?.textFields?[0].text else { return }
                    self?.notes[indexPath.item].title = newNote
                    self?.save()
                    self?.collectionView.reloadData()
                })
                present(ac, animated: true)
            }
        }
    }
    @objc func addNote(){
        let ac = UIAlertController(title: "Add a Note", message: nil, preferredStyle: .alert)
        ac.addTextField()
        let add = UIAlertAction(title: "Add", style: .default) {
            [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
            self?.save()
        }
        ac.addAction(add)
        present(ac, animated: true)
    }
    func submit(_ Item: String) {
        let newNote = Note(title: Item, text: "")
        notes.insert(newNote, at: 0)
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.insertItems(at: [indexPath])
        return
    }
    func userLogin() {
        if let passWord = KeychainWrapper.standard.string(forKey: "notesPassword") {
            enterCurrentPassWord(passWord)
        } else {
            requestNewPassword()
        }
    }
    
    
    func requestNewPassword() {
        let ac = UIAlertController(title: "Create a Password", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "save", style: .default, handler: { [weak self, weak ac] _ in
            if let newPassWord = ac?.textFields?[0].text {
                KeychainWrapper.standard.set(newPassWord, forKey: "notesPassword")
                self?.view.isHidden = false
            }
        }))
        present(ac, animated: true)
        
    }
    func enterCurrentPassWord(_ passWord: String?) {
        let ac = UIAlertController(title: "Enter Password", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.textFields?[0].isSecureTextEntry = true
        func enterPass(_ action: UIAlertAction) {
            if let enteredText = ac.textFields?[0].text {
                if enteredText == passWord {
                    self.view.isHidden = false
                } else {
                    enterCurrentPassWord(passWord)
                }
            }

        }
        
        let enterPassWord = UIAlertAction(title: "Ok", style: .default, handler: enterPass)
        ac.addAction(enterPassWord)
        present(ac, animated: true)
    }
    
    
    
    func save() {
        let jsonEncoder = JSONEncoder()
        if let savedData = try? jsonEncoder.encode(notes) {
            let defaults = UserDefaults.standard
            defaults.set(savedData, forKey: "notes")
        } else {
            print("failed saving")
        }
    }
    
    
    // MARK: UICollectionViewDataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return notes.count
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? NoteCell else {
            fatalError("Unable to dequeue Cell.")
        }
        let note = notes[indexPath.item]
        cell.noteTitle.text = note.title
        cell.layer.cornerRadius = 30
        return cell
    }
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "NoteContent") as? ViewController {
            vc.note = notes[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.save()
        self.collectionView.reloadData()
    }
    
    
}





