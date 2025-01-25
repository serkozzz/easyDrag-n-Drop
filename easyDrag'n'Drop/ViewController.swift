//
//  ViewController.swift
//  easyDrag'n'Drop
//
//  Created by Sergey Kozlov on 21.01.2025.
//

import UIKit


struct Card: Hashable {
    var title: String
    var id = UUID()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.id == rhs.id
    }
}

var cards = [Card(title: "1"),
             Card(title: "2"),
             Card(title: "3"),
             Card(title: "4"),
             Card(title: "5"),
             Card(title: "6")]

class ViewController: UICollectionViewController {

    
    var dataSource: UICollectionViewDiffableDataSource<Int, Card>!
    var isFirstDropUpdate = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.dragInteractionEnabled = true // Включить drag
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.collectionViewLayout = createLayout()
        
        let registration = cellRegistration
        dataSource = UICollectionViewDiffableDataSource<Int, Card>(collectionView: collectionView) { collectionView, indexPath, card in
            let cell = collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: card)
            return cell
        }
        applySnapshot()
    }

    var cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, Card> { cell, indexPath, card in
        var contentConf = UIListContentConfiguration.cell()
        contentConf.text = card.title
        cell.contentConfiguration = contentConf
        
        var backgroundConf = cell.defaultBackgroundConfiguration()
        backgroundConf.backgroundColor = .yellow
        backgroundConf.strokeWidth = 3
        backgroundConf.strokeColor = .black
        cell.backgroundConfiguration = backgroundConf
    }

    func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Card>()
        snapshot.appendSections([0])
        snapshot.appendItems(cards)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension ViewController {
    func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalWidth(0.33))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.33))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(5)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}


extension ViewController:  UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        isFirstDropUpdate = true
        let itemProvider = NSItemProvider(object: NSString())
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = cards[indexPath.item]
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    
        let item = cards[indexPath.item].title as NSString
        let itemProvider = NSItemProvider(object: item)
        return [UIDragItem(itemProvider: itemProvider)]
    }
    

    func collectionView(
        _ collectionView: UICollectionView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        
        if let dstIdxPath = destinationIndexPath {
        
            let srcItemID = session.localDragSession!.items.first!.localObject as! Card
            let dstItemID = dataSource.itemIdentifier(for: dstIdxPath)!
            
            if dstItemID != srcItemID {
                let srcIdxPath = dataSource.indexPath(for: srcItemID)!
                var snap = dataSource.snapshot()
                if dstIdxPath.item > srcIdxPath.item {
                    snap.moveItem(srcItemID, afterItem: dstItemID)
                } else {
                    snap.moveItem(srcItemID, beforeItem: dstItemID)
                }
                dataSource.apply(snap)
            }
        }
        
        return UICollectionViewDropProposal(operation: .move)
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              let dragItem = coordinator.items.first?.dragItem
        else { return }
        

        let movedCard = cards.remove(at: coordinator.items.first!.sourceIndexPath!.item)
        cards.insert(movedCard, at: destinationIndexPath.item)
        
//        applySnapshot()
//        coordinator.drop(dragItem, toItemAt: destinationIndexPath)
        
//        let srcItemID = coordinator.session.localDragSession!.items.first!.localObject as! Card
//        let dstItemID = dataSource.itemIdentifier(for: destinationIndexPath)!
//        
        let destCell = collectionView.cellForItem(at: destinationIndexPath)!
        let anim = coordinator.drop(dragItem, intoItemAt: destinationIndexPath, rect: destCell.bounds)
    }
}
