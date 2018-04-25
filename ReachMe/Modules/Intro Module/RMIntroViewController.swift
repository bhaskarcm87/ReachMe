//
//  RMIntroViewController.swift
//  ReachMe
//
//  Created by Sachin Kumar Patra on 2/15/18.
//  Copyright © 2018 sachin. All rights reserved.
//

import UIKit

class RMIntroViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var enterButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    lazy var pageViewController: UIPageViewController = {
        let pageVC = childViewControllers.first as! UIPageViewController
        pageVC.delegate = self
        pageVC.dataSource = self
        pageVC.scrollView?.delegate = self
        return pageVC
    }()
    lazy var orderedViewControllers: [UIViewController] = {
        return [newVc(viewController: "IntroScreen1"),
                newVc(viewController: "IntroScreen2"),
                newVc(viewController: "IntroScreen3"),
                newVc(viewController: "IntroScreen4")]
    }()
    lazy var orderedPageColors: [UIColor] = {
        return [UIColor.introPage1Color(),
                UIColor.introPage2Color(),
                UIColor.introPage3Color(),
                UIColor.introPage4Color()]
    }()
    
    var previousPagePosition: CGFloat?
    var expectedTransitionIndex: Int?
    public enum NavigationDirection {
        case neutral
        case forward
        case reverse
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Constants.appDelegate.window?.rootViewController = navigationController

        if let firstViewContrller = orderedViewControllers.first {
            pageViewController.setViewControllers([firstViewContrller], direction: .forward, animated: true, completion: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func newVc(viewController: String) -> UIViewController {
        return storyboard!.instantiateViewController(withIdentifier: viewController)
    }
    
    // MARK: - Button Actions
    @IBAction func enterButtonAction(_ sender: UIButton) {
        if let _ = sender.currentTitle?.isEmpty {
           performSegue(withIdentifier: Constants.Segues.LOGIN, sender: self)

        } else {
            guard let currentViewController = pageViewController.viewControllers?.first else { return }
            
            guard let nextViewController = pageViewController.dataSource?.pageViewController(pageViewController, viewControllerAfter: currentViewController) else { return }
            pageViewController.setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
            pageViewController.delegate?.pageViewController!(pageViewController, didFinishAnimating: true, previousViewControllers: [], transitionCompleted: true)
        }
    }

}

// MARK: - UIPageController Datasource
extension RMIntroViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewContrllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewContrllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }

        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewContrllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewContrllerIndex + 1
        guard orderedViewControllers.count != nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
}

// MARK: - UIPageController Delegate
extension RMIntroViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        let pageContentViewController = pageViewController.viewControllers![0]
        
        guard let index = orderedViewControllers.index(of: pageContentViewController) else {return}
        pageControl.currentPage = index
        if index == 0 {
            view.backgroundColor = UIColor.introPage1Color()
        }
        if index == 3 {
            enterButton.setImage(nil, for: .normal)
            enterButton.setTitle("Enter", for: .normal)
            skipButton.isEnabled = false
            view.backgroundColor = UIColor.introPage4Color()
        } else {
            enterButton.setImage(#imageLiteral(resourceName: "ic_arrow_left"), for: .normal)
            enterButton.setTitle(nil, for: .normal)
            skipButton.isEnabled = true
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first,
            let index = orderedViewControllers.index(of: viewController) else {
                return
        }
        self.expectedTransitionIndex = index
    }
}

// MARK: - PageConroller ScrollviewDelegate
extension RMIntroViewController: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let (pageSize, contentOffset) = calculateRelativePageSizeAndContentOffset(for: scrollView)
        
        guard let scrollIndexDiff = pageScrollIndexDiff(forCurrentIndex: pageControl.currentPage,
                                                        expectedIndex: self.expectedTransitionIndex,
                                                        currentContentOffset: contentOffset,
                                                        pageSize: pageSize) else { return }
        
        guard let pagePosition = pagePosition(forContentOffset: contentOffset,
                                              pageSize: pageSize,
                                              indexDiff: scrollIndexDiff) else { return }
        
        // do not continue if previous position equals current
        if previousPagePosition == pagePosition { return }
        previousPagePosition = pagePosition
        
        //Start Transtion of color
        var offset = pagePosition
        if offset < 0.0 || offset > 3 {
            offset = 1.0 + offset
            return
        }
        
        var integral: Double = 0.0
        let percentage = CGFloat(modf(Double(offset), &integral))
        let lowerIndex = Int(floor(pagePosition))
        let upperIndex = Int(ceil(pagePosition))
        
        let transitionColor = interpolate(betweenColor: orderedPageColors[lowerIndex],
                                   and: orderedPageColors[upperIndex],
                                   percent: percentage)
        view.backgroundColor = transitionColor
    }
}

// MARK: - ColorTransition Methods
extension RMIntroViewController {
    private func calculateRelativePageSizeAndContentOffset(for scrollView: UIScrollView) -> (CGFloat, CGFloat) {
        var pageSize: CGFloat
        var contentOffset: CGFloat
        
            pageSize = scrollView.frame.size.width
            if (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft) {
                contentOffset = pageSize + (pageSize - scrollView.contentOffset.x)
            } else {
                contentOffset = scrollView.contentOffset.x
            }
        return (pageSize, contentOffset)
    }
    
    private func pageScrollIndexDiff(forCurrentIndex index: Int?,
                                     expectedIndex: Int?,
                                     currentContentOffset: CGFloat,
                                     pageSize: CGFloat) -> CGFloat? {
        guard let index = index else {
            return nil
        }
        
        let expectedIndex = expectedIndex ?? index
        let expectedDiff = CGFloat(max(1, abs(expectedIndex - index)))
        return expectedDiff
    }
    
    private func pagePosition(forContentOffset contentOffset: CGFloat,
                              pageSize: CGFloat,
                              indexDiff: CGFloat) -> CGFloat? {
        
        let scrollOffset = contentOffset - pageSize
        let pageOffset = (CGFloat(pageControl.currentPage) * pageSize) + (scrollOffset * indexDiff)
        let position = pageOffset / pageSize
        return position.isFinite ? position : 0
    }
    
    func interpolate(betweenColor colorA: UIColor,
                     and colorB: UIColor,
                     percent: CGFloat) -> UIColor? {
        var redA: CGFloat = 0.0
        var greenA: CGFloat = 0.0
        var blueA: CGFloat = 0.0
        var alphaA: CGFloat = 0.0
        guard colorA.getRed(&redA, green: &greenA, blue: &blueA, alpha: &alphaA) else {
            return nil
        }
        
        var redB: CGFloat = 0.0
        var greenB: CGFloat = 0.0
        var blueB: CGFloat = 0.0
        var alphaB: CGFloat = 0.0
        guard colorB.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB) else {
            return nil
        }
        
        let iRed = CGFloat(redA + percent * (redB - redA))
        let iBlue = CGFloat(blueA + percent * (blueB - blueA))
        let iGreen = CGFloat(greenA + percent * (greenB - greenA))
        let iAlpha = CGFloat(alphaA + percent * (alphaB - alphaA))
        
        return UIColor(red: iRed, green: iGreen, blue: iBlue, alpha: iAlpha)
    }
}

internal extension UIPageViewController {
    var scrollView: UIScrollView? {
        for subview in self.view.subviews {
            if let scrollView = subview as? UIScrollView {
                return scrollView
            }
        }
        return nil
    }
}
