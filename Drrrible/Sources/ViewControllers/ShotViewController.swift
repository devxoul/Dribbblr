//
//  ShotViewController.swift
//  Drrrible
//
//  Created by Suyeol Jeon on 12/03/2017.
//  Copyright © 2017 Suyeol Jeon. All rights reserved.
//

import UIKit

import ReactorKit
import ReusableKit
import RxCocoa
import RxDataSources
import Umbrella
import URLNavigator

final class ShotViewController: BaseViewController, View {

  // MARK: Constants

  fileprivate struct Reusable {
    static let imageCell = ReusableCell<ShotViewImageCell>()
    static let titleCell = ReusableCell<ShotViewTitleCell>()
    static let textCell = ReusableCell<ShotViewTextCell>()
    static let reactionCell = ReusableCell<ShotViewReactionCell>()
    static let commentCell = ReusableCell<ShotViewCommentCell>()
    static let activityIndicatorCell = ReusableCell<CollectionActivityIndicatorCell>()
  }

  fileprivate struct Metric {
  }


  // MARK: Properties

  fileprivate let analytics: DrrribleAnalytics
  fileprivate let dataSource = RxCollectionViewSectionedReloadDataSource<ShotViewSection>()


  // MARK: UI

  let refreshControl = UIRefreshControl()
  let collectionView = UICollectionView(
    frame: .zero,
    collectionViewLayout: UICollectionViewFlowLayout()
  ).then {
    $0.backgroundColor = .clear
    $0.alwaysBounceVertical = true
    $0.register(Reusable.imageCell)
    $0.register(Reusable.titleCell)
    $0.register(Reusable.textCell)
    $0.register(Reusable.reactionCell)
    $0.register(Reusable.commentCell)
    $0.register(Reusable.activityIndicatorCell)
  }


  // MARK: Initializing

  init(reactor: ShotViewReactor, analytics: DrrribleAnalytics) {
    defer { self.reactor = reactor }
    self.analytics = analytics
    super.init()
    self.title = "shot".localized
  }
  
  required convenience init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }


  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .db_background

    self.collectionView.addSubview(self.refreshControl)
    self.view.addSubview(self.collectionView)
  }

  override func setupConstraints() {
    self.collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }


  // MARK: Configuring

  func bind(reactor: ShotViewReactor) {
    self.collectionView.rx.setDelegate(self).addDisposableTo(self.disposeBag)

    self.dataSource.configureCell = { dataSource, collectionView, indexPath, sectionItem in
      switch sectionItem {
      case .image(let reactor):
        let cell = collectionView.dequeue(Reusable.imageCell, for: indexPath)
        cell.reactor = reactor
        return cell

      case .title(let reactor):
        let cell = collectionView.dequeue(Reusable.titleCell, for: indexPath)
        cell.reactor = reactor
        return cell

      case .text(let reactor):
        let cell = collectionView.dequeue(Reusable.textCell, for: indexPath)
        cell.reactor = reactor
        return cell

      case .reaction(let reactor):
        let cell = collectionView.dequeue(Reusable.reactionCell, for: indexPath)
        cell.reactor = reactor
        return cell

      case .comment(let reactor):
        let cell = collectionView.dequeue(Reusable.commentCell, for: indexPath)
        cell.reactor = reactor
        return cell

      case .activityIndicator:
        return collectionView.dequeue(Reusable.activityIndicatorCell, for: indexPath)
      }
    }

    // Input
    self.rx.viewDidLoad
      .map { Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    self.refreshControl.rx.controlEvent(.valueChanged)
      .map { Reactor.Action.refresh }
      .bind(to: reactor.action)
      .disposed(by: self.disposeBag)

    // Output
    reactor.state.map { $0.sections }
      .map { $0.isEmpty }
      .bind(to: self.collectionView.rx.isHidden)
      .disposed(by: self.disposeBag)

    reactor.state.map { $0.isRefreshing }
      .distinctUntilChanged()
      .bind(to: self.refreshControl.rx.isRefreshing)
      .disposed(by: self.disposeBag)

    reactor.state.map { $0.sections }
      .bind(to: self.collectionView.rx.items(dataSource: self.dataSource))
      .disposed(by: self.disposeBag)

    // View
    self.rx.viewDidAppear
      .subscribe(onNext: { [weak self] _ in
        self?.analytics.log(.viewShot(shotID: reactor.currentState.shotID))
      })
      .disposed(by: self.disposeBag)
  }

}


// MARK: - UICollectionViewDelegateFlowLayout

extension ShotViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return 0
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let sectionWidth = collectionView.sectionWidth(at: indexPath.section)
    let sectionItem = self.dataSource[indexPath]
    switch sectionItem {
    case .image(let reactor):
      return Reusable.imageCell.class.size(width: sectionWidth, reactor: reactor)

    case .title(let reactor):
      return Reusable.titleCell.class.size(width: sectionWidth, reactor: reactor)

    case .text(let reactor):
      return Reusable.textCell.class.size(width: sectionWidth, reactor: reactor)

    case .reaction(let reactor):
      return Reusable.reactionCell.class.size(width: sectionWidth, reactor: reactor)

    case .comment(let reactor):
      return Reusable.commentCell.class.size(width: sectionWidth, reactor: reactor)

    case .activityIndicator:
      return Reusable.activityIndicatorCell.class.size(width: sectionWidth)
    }
  }
}
