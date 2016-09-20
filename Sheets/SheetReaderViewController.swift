//
//  SheetReaderViewController.swift
//  Sheets
//
//  Created by Keiwan Donyagard on 06.07.16.
//  Copyright © 2016 Keiwan Donyagard. All rights reserved.
//

import Foundation
import UIKit
import vfrReader
import MessageUI

protocol SheetReaderViewControllerDelegate {
    func dismissReaderViewController(_ viewController: SheetReaderViewController)
}

class SheetReaderViewController: UIViewController, UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate, ReaderMainToolbarDelegate, ReaderMainPagebarDelegate, ReaderContentViewDelegate, ThumbsViewControllerDelegate {
    
    //ReaderConstants
    let READER_FLAT_UI = true
    let READER_SHOW_SHADOWS = true
    let READER_ENABLE_THUMBS = true
    let READER_DISABLE_RETINA = false
    let READER_ENABLE_PREVIEW = true
    let READER_DISABLE_IDLE = false
    let READER_STANDALONE = false
    let READER_BOOKMARKS = true
    
    
    var document: ReaderDocument!
    var theScrollView: UIScrollView!
    
    var mainToolbar: ReaderMainToolbar!
    var mainPagebar: ReaderMainPagebar!
    
    var contentViews: NSMutableDictionary!
    var userInterfaceIdiom: UIUserInterfaceIdiom!
    
    var currentPage: Int! = 0
    var minimumPage: Int! = 0
    var maximumPage: Int! = 0
    
    var documentInteraction: UIDocumentInteractionController!
    var printInteraction: UIPrintInteractionController!
    
    var scrollViewOutset: CGFloat!
    var lastAppearSize: CGSize!
    var lastHideTime: Date!
    
    var ignoreDidScroll = false
    
    //other constants
    let STATUS_HEIGHT: CGFloat = 20
    
    let TOOLBAR_HEIGHT: CGFloat = 44
    let PAGEBAR_HEIGHT: CGFloat = 48
    
    let SCROLLVIEW_OUTSET_SMALL: CGFloat = 4
    let SCROLLVIEW_OUTSET_LARGE: CGFloat = 8
    
    let TAP_AREA_SIZE: CGFloat = 48
    
    
    //Delegate
    var delegate: SheetReaderViewControllerDelegate!
    
    // SheetReaderViewController functions
    func updateContentSize(_ scrollView: UIScrollView){
        
        let contentHeight = scrollView.bounds.size.height   // Height
        let contentWidth = (scrollView.bounds.size.width * CGFloat(maximumPage))
        
        scrollView.contentSize = CGSize(width: contentWidth, height: contentHeight)
    }
    
    func updateContentViews(_ scrollView: UIScrollView){
        
        self.updateContentSize(scrollView)  //Update content size first
        
        contentViews.enumerateKeysAndObjects({  //Enumerate content views
            (key, contentView, stop) in
                let page = (key as AnyObject).intValue!  // Page numebr value
                var viewRect = CGRect.zero
            
                viewRect.size = scrollView.bounds.size
                viewRect.origin.x = viewRect.size.width * (CGFloat(page) - 1) // Update X
            
                (contentView as! ReaderContentView).frame = viewRect.insetBy(dx: self.scrollViewOutset, dy: 0)
        })
        
        let page = currentPage
        let contentOffset = CGPoint(x: scrollView.bounds.size.width * (CGFloat(page!) - 1), y: 0)
        
        if(scrollView.contentOffset.equalTo(contentOffset)){
            scrollView.contentOffset = contentOffset    // Update content offset
        }
        
        mainToolbar.setBookmarkState(document.bookmarks.contains(page!))
        mainPagebar.update()  // Update page bar
    }
    
    func addContentView(_ scrollView: UIScrollView, page: Int){
        var viewRect = CGRect.zero
        
        viewRect.size = scrollView.bounds.size
        viewRect.origin.x = (viewRect.size.width * (CGFloat(page) - 1))
        viewRect = viewRect.insetBy(dx: self.scrollViewOutset, dy: 0)
        
        //document properties
        let fileURL = document.fileURL
        let phrase = document.password
        let guid = document.guid
        
        // Reader Content View
        let contentView = ReaderContentView(
            frame: viewRect,
            fileURL: fileURL,
            page: UInt(page),
            password: phrase
        )
        
        contentView?.message = self
        contentViews.setObject(contentView, forKey: page as NSCopying)
        scrollView.addSubview(contentView!)
        
        // Request page preview thumb
        contentView?.showPageThumb(fileURL, page: page, password: phrase, guid: guid)
    }
    
    func layoutContentViews(_ scrollView: UIScrollView){
        let viewWidth = scrollView.bounds.size.width  // View width
        let contentOffsetX = scrollView.contentOffset.x  // Content offset x
        
        var pageB = (contentOffsetX + viewWidth - 1) / viewWidth    // Pages
        var pageA = contentOffsetX / viewWidth
        pageB += 2  // Add extra pages
        
        if pageA < CGFloat(minimumPage) {
            pageA = CGFloat(minimumPage)
        }
        
        if pageB > CGFloat(maximumPage) {
            pageB = CGFloat(maximumPage)
        }
        
        // Make page range (A to B)
        let pageRange = NSMakeRange(Int(pageA), Int(pageB - pageA + 1))
        let pageSet = NSMutableIndexSet(integersIn: pageRange.toRange() ?? 0..<0)
        
        //Enumerate content views
        for key: NSNumber in (contentViews.allKeys as! [NSNumber]) {
            let page = key.intValue  // Page number value
            
            if !pageSet.contains(page) {   // remove content view
                
                let contentView = contentViews.object(forKey: key)
                
                (contentView as AnyObject).removeFromSuperview()
                contentViews.removeObject(forKey: key)
            } else {    // visible contnet view - so remove it from page set
                pageSet.remove(page)
            }
        }
        
        let pages = pageSet.count
        
        if pages > 0 {  // We have pages to add
            
            var options: NSEnumerationOptions = .concurrent  // Default
            
            if pages == 2 { // Handle case of only two content views
                if (maximumPage > 2) && pageSet.last == maximumPage {
                    options = .reverse
                }
            } else if (pages == 3) {  // Handle three content views - show the middle one first
                let workSet = pageSet.mutableCopy()
                options = .reverse
                
                workSet.remove(pageSet.first)
                workSet.remove(pageSet.last)
                
                let page = workSet.first
                pageSet.remove(page)
                
                self.addContentView(scrollView, page: page)
            }
            
            pageSet.enumerate(options: options, using: {
                (page, stop) in
                    self.addContentView(scrollView, page: page)
            })
        }
    }
    
    func handleScrollViewDidEnd(_ scrollView: UIScrollView){
        let viewWidth = scrollView.bounds.size.width; // Scroll view width
        let contentOffsetX = scrollView.contentOffset.x; // Content offset X
        var page = Int(contentOffsetX / viewWidth) // Page number
        page += 1
        
        if page != currentPage { // Only if on different page
            currentPage = page
            document.pageNumber = page as NSNumber!
            
            contentViews.enumerateKeysAndObjects({ // Enumerate content views
                (key, contentView, stop) in
                    if (key as AnyObject).intValue != page {
                        (contentView as AnyObject).zoomReset(animated: false)
                    }
            })
            
            mainToolbar.setBookmarkState(document.bookmarks.contains(page))
            mainPagebar.update() // Update page bar
        }
    }
    
    func showDocumentPage(_ page: Int){
        
        if page != currentPage { // Only if on different page
            if page < minimumPage || page > maximumPage {
                return
            }
            
            currentPage = page
            document.pageNumber = page as NSNumber!
            
            let contentOffset = CGPoint(x: (theScrollView.bounds.size.width * (CGFloat(page) - 1)), y: 0)
            
            if theScrollView.contentOffset.equalTo(contentOffset) {
                self.layoutContentViews(theScrollView)
            } else {
                theScrollView.setContentOffset(contentOffset, animated: false)
            }
            
            contentViews.enumerateKeysAndObjects({
                (key, contentView, stop) in
                
                    if (key as AnyObject).intValue != page {
                        (contentView as AnyObject).zoomReset(animated: false)
                    }
            })
            
            mainToolbar.setBookmarkState(document.bookmarks.contains(page))
            mainPagebar.update()
        }
    }
    
    func showDocument(){
        self.updateContentSize(theScrollView)   // Update content size first
        self.showDocumentPage(document.pageNumber.intValue) // Show page
        
        document.lastOpen = Date() // Update document last opened date
    }
    
    func closeDocument(){
        if printInteraction != nil {
            printInteraction.dismiss(animated: false)
        }
        
        document.archiveDocumentProperties() // save any ReaderDocument changes
        
        ReaderThumbQueue.sharedInstance().cancelOperations(withGUID: document.guid)
        ReaderThumbCache.sharedInstance().removeAllObjects() // Empty the thumb cache
        
        delegate.dismissReaderViewController(self) // Dismiss the ReaderViewController
    }
    
    
    // UIViewController methods
    
    init(object: ReaderDocument?){
        super.init(nibName: nil, bundle: nil) // Initialize superclass
        
        if object != nil && (object?.isKind(of: ReaderDocument.self))!{ // Valid object
            
            userInterfaceIdiom = UIDevice.current.userInterfaceIdiom // User interface idiom
            
            let notificationCenter = NotificationCenter.default // Default notification center
            notificationCenter.addObserver(self, selector: #selector(SheetReaderViewController.applicationWillResign(_:)), name: NSNotification.Name.UIApplicationWillTerminate, object: nil)
            notificationCenter.addObserver(self, selector: #selector(SheetReaderViewController.applicationWillResign(_:)), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
            
            if userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                scrollViewOutset = SCROLLVIEW_OUTSET_LARGE
            } else {
                scrollViewOutset = SCROLLVIEW_OUTSET_SMALL
            }
            
            object?.updateProperties()
            document = object! // Retain the supplied ReaderDocument object for our use
            
            ReaderThumbCache.touch(withGUID: object?.guid) // Touch the document thumb cache directory
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(document != nil) // Must have a valid ReaderDocument
        
        self.view.backgroundColor = UIColor.gray // Neutral grey
        
        var fakeStatusBar: UIView?
        var viewRect = self.view.bounds // View bounds
        
        //IOS 7+
        if !self.prefersStatusBarHidden {
            var statusBarRect = viewRect
            statusBarRect.size.height = STATUS_HEIGHT
            fakeStatusBar = UIView(frame: statusBarRect) // UIView
            fakeStatusBar?.autoresizingMask = .flexibleWidth
            fakeStatusBar?.backgroundColor = UIColor.black
            fakeStatusBar?.contentMode = .redraw
            fakeStatusBar?.isUserInteractionEnabled = false
            
            viewRect.origin.y += STATUS_HEIGHT
            viewRect.size.height -= STATUS_HEIGHT
        }
        
        let scrollViewRect = viewRect.insetBy(dx: -scrollViewOutset, dy: 0)
        theScrollView = UIScrollView(frame: scrollViewRect) // All
        theScrollView.autoresizesSubviews = false
        theScrollView.contentMode = .redraw
        theScrollView.showsHorizontalScrollIndicator = false
        theScrollView.showsVerticalScrollIndicator = false
        theScrollView.scrollsToTop = false
        theScrollView.delaysContentTouches = false
        theScrollView.isPagingEnabled = true
        theScrollView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        theScrollView.backgroundColor = UIColor.clear
        theScrollView.delegate = self
        self.view.addSubview(theScrollView)
        
        var toolbarRect = viewRect
        toolbarRect.size.height = TOOLBAR_HEIGHT
        mainToolbar = ReaderMainToolbar(frame: toolbarRect, document: document) // ReaderMainToolbar
        mainToolbar.delegate = self // ReaderMainToolbarDelegate
        self.view.addSubview(mainToolbar)
        
        var pagebarRect = self.view.bounds
        pagebarRect.size.height = PAGEBAR_HEIGHT
        pagebarRect.origin.y = self.view.bounds.size.height - pagebarRect.size.height
        mainPagebar = ReaderMainPagebar(frame: pagebarRect, document: document) // ReaderMainPagebar
        mainPagebar.delegate = self // ReaderMainPagebarDelegate
        self.view.addSubview(mainPagebar)
        
        if fakeStatusBar != nil {
            self.view.addSubview(fakeStatusBar!) // Add status bar background view
        }
        
        let singleTapOne = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapOne.numberOfTouchesRequired = 1
        singleTapOne.numberOfTapsRequired = 1
        singleTapOne.delegate = self
        self.view.addGestureRecognizer(singleTapOne)
        
        let doubleTapOne = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapOne.numberOfTouchesRequired = 1
        doubleTapOne.numberOfTapsRequired = 2
        doubleTapOne.delegate = self
        self.view.addGestureRecognizer(doubleTapOne)
        
        let doubleTapTwo = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapTwo.numberOfTouchesRequired = 2
        doubleTapTwo.numberOfTapsRequired = 2
        doubleTapTwo.delegate = self
        self.view.addGestureRecognizer(doubleTapTwo)
        
        singleTapOne.require(toFail: doubleTapOne) // Single tap requires double tap to fail
        
        contentViews = NSMutableDictionary()
        lastHideTime = Date()
        
        minimumPage = 1
        maximumPage = document.pageCount.intValue
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if lastAppearSize != nil {
            if !lastAppearSize.equalTo(CGSize.zero) {
                if !lastAppearSize.equalTo(self.view.bounds.size) {
                    self.updateContentViews(theScrollView) // Update content views
                }
            }
        } else {
            self.updateContentViews(theScrollView) // Update content views
            lastAppearSize = CGSize.zero // Reset view size tracking
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !theScrollView.contentSize.equalTo(CGSize.zero) {
            self.perform(#selector(showDocument), with: nil, afterDelay: 0)
        }
        
        if READER_DISABLE_IDLE { // Option
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        lastAppearSize = self.view.bounds.size // Track view size
        if READER_DISABLE_IDLE {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    /* ViewDidUnload deprecated starting at IOS 6*/
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if userInterfaceIdiom == .pad {
            if printInteraction != nil {
                printInteraction.dismiss(animated: false)
            }
        }
        ignoreDidScroll = true
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if !theScrollView.contentSize.equalTo(CGSize.zero) {
            self.updateContentViews(theScrollView)
            lastAppearSize = CGSize.zero
        }
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        ignoreDidScroll = false
    }
    
    override func didReceiveMemoryWarning() {
        //NSLog("%s",#function) // ONly when Debugging
        super.didReceiveMemoryWarning()
    }
    
    
    // UIScrollViewDelegate methods
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !ignoreDidScroll {
            self.layoutContentViews(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.handleScrollViewDidEnd(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.handleScrollViewDidEnd(scrollView)
    }
    
    // UIGestureRecognizerDelegate methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if ((touch.view?.isKind(of: UIScrollView.self)) != nil) {
            return true
        }
        return false
    }
    
    // UIGestureRecognizer action methods
    
    func decrementPageNumber(){
        if maximumPage > minimumPage && currentPage != minimumPage {
            var contentOffset = theScrollView.contentOffset // Offset
            contentOffset.x -= theScrollView.bounds.size.width // View X--
            
            theScrollView.setContentOffset(contentOffset, animated: true)
        }
    }
    
    func incrementPageNumber(){
        if maximumPage > minimumPage && currentPage != maximumPage {
            var contentOffset = theScrollView.contentOffset // Offset
            contentOffset.x += theScrollView.bounds.size.width // View X++
            
            theScrollView.setContentOffset(contentOffset, animated: true)
        }
    }
    
    // UITapGestureRecognizer methods
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer){
        if recognizer.state == UIGestureRecognizerState.recognized {
            let viewRect = recognizer.view?.bounds // View bounds
            let point = recognizer.location(in: recognizer.view) // Point
            let areaRect = viewRect!.insetBy(dx: TAP_AREA_SIZE, dy: 0) // Area rect
            
            if areaRect.contains(point) { // Single tap is inside area
                let key = currentPage // Page number key
                let targetView = contentViews.object(forKey: key) // View
                
                let target = (targetView as AnyObject).processSingleTap(recognizer) // Target object
                
                if target != nil { // Handle the returned target object
                    if target is NSURL  { // Open a URL
                        var url = target as! URL // cast to a NSURL object
                        
                        if !UIApplication.shared.canOpenURL(url) { // Handle a missing URL scheme
                            let www = url.absoluteString
                            if www.hasPrefix("www") { // Check for www prefix
                                let http = NSString(format: "http://%s", www)
                                url = URL(string: http as String)! // Proper http-based URL
                            }
                        }
                        
                        if !UIApplication.shared.openURL(url) {
                            // print("Bad or unknown URL") // Only on DEBUG
                        }
                    } else { // Not a URL, so check for another possible object type
                        if target is Int { // Goto page
                            let number = target as! Int
                            
                            self.showDocumentPage(number) // Show the page
                        }
                    }
                } else { // Nothing active tapped in the target content view
                    if lastHideTime.timeIntervalSinceNow < -0.75 { // Delay since hide
                        if mainToolbar.alpha < 1.0 || mainPagebar.alpha < 1 { // Hidden
                            mainToolbar.show()
                            mainPagebar.show()
                        }
                    }
                }
                return
            }
            
            var nextPageRect = viewRect!
            nextPageRect.size.width = TAP_AREA_SIZE
            nextPageRect.origin.x = (viewRect?.size.width)! - TAP_AREA_SIZE
            
            if nextPageRect.contains(point) { // page++
                self.incrementPageNumber()
                return
            }
            
            var prevPageRect = viewRect!
            prevPageRect.size.width = TAP_AREA_SIZE
            
            if prevPageRect.contains(point) { // page--
                self.decrementPageNumber()
                return
            }
        }
    }
    
    func handleDoubleTap(_ recognizer: UITapGestureRecognizer){
        if recognizer.state == UIGestureRecognizerState.recognized {
            let viewRect = recognizer.view?.bounds // View bounds
            let point = recognizer.location(in: recognizer.view) // Point
            let zoomArea = viewRect!.insetBy(dx: TAP_AREA_SIZE, dy: TAP_AREA_SIZE) // Area
            
            if zoomArea.contains(point) { // Double tap is inside zoom area
                let key = currentPage // Page number key
                let targetView = contentViews.object(forKey: key) // View
                
                switch recognizer.numberOfTapsRequired { // Touches count
                case 1: // One finger double tap: zoom++
                    (targetView as AnyObject).zoomIncrement(recognizer)
                    break
                case 2:
                    (targetView as AnyObject).zoomIncrement(recognizer)
                    break
                default:
                    print("Error with recognizer number of Taps")
                    break
                }
                
                return
            }
            
            var nextPageRect = viewRect!
            nextPageRect.size.width = TAP_AREA_SIZE
            nextPageRect.origin.x = (viewRect?.size.width)! - TAP_AREA_SIZE
            
            if nextPageRect.contains(point) { // Page++
                self.incrementPageNumber()
                return
            }
            
            var prevPageRect = viewRect!
            prevPageRect.size.width = TAP_AREA_SIZE
            
            if prevPageRect.contains(point) { // page--
                self.decrementPageNumber()
                return
            }
        }
    }
    
    
    // ReaderContentViewDelegate methods
    
    func contentView(_ contentView: ReaderContentView!, touchesBegan touches: Set<NSObject>!) {
        if mainToolbar.alpha > 0 || mainPagebar.alpha > 0 {
            if touches.count == 1 { // Single touches only
                let touch = touches?.first as? UITouch
                let point = touch?.location(in: self.view)
                let areaRect = self.view.bounds.insetBy(dx: TAP_AREA_SIZE, dy: TAP_AREA_SIZE)
                
                if !areaRect.contains(point!) {
                    return
                }
                
                //Hide
                mainToolbar.hide()
                mainPagebar.hide()
                
                lastHideTime = Date() // Set last hide time
            }
        }
    }
    
    // ReaderMainToolbarDelegate methods
    
    func tapped(in toolbar: ReaderMainToolbar!, doneButton button: UIButton!) {
        if !READER_STANDALONE {
            self.closeDocument() // Close ReaderViewController
        }
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, thumbsButton button: UIButton!) {
        if READER_ENABLE_THUMBS {
            if printInteraction != nil {
                printInteraction.dismiss(animated: false)
            }
            
            let thumbsViewController = ThumbsViewController(readerDocument: document)
            
            thumbsViewController?.title = self.title
            thumbsViewController?.delegate = self // ThumbsViewControllerDelegate
            
            thumbsViewController?.modalTransitionStyle = .crossDissolve
            thumbsViewController?.modalPresentationStyle = .fullScreen
            
            self.present(thumbsViewController!, animated: false, completion: nil)
        }
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, export button: UIButton!) {
        if printInteraction != nil {
            printInteraction.dismiss(animated: true)
        }
        let fileURL = document.fileURL // Document file URL
        
        documentInteraction = UIDocumentInteractionController(url: fileURL!)
        documentInteraction.delegate = self // UIDOcumentINteractionControllerDelegate
        
        documentInteraction.presentOpenInMenu(from: button.bounds, in: button, animated: true)
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, print button: UIButton!) {
        if UIPrintInteractionController.isPrintingAvailable {
            let fileURL = document.fileURL // Document dile URL
            
            if UIPrintInteractionController.canPrint(fileURL!) {
                printInteraction = UIPrintInteractionController.shared
                
                let printInfo = UIPrintInfo.printInfo()
                printInfo.duplex = .longEdge
                printInfo.outputType = .general
                printInfo.jobName = document.fileName
                
                printInteraction.printInfo = printInfo
                printInteraction.printingItem = fileURL
                printInteraction.showsPageRange = true
                
                if userInterfaceIdiom == .pad { // Large device printing
                    printInteraction.present(from: button.bounds, in: button, animated: true, completionHandler: {
                        (pic, completed, error) in
                        if !completed && error != nil {
                            print("Error print could not be completed")
                        }
                    })
                } else { // Handle printing on small device
                    printInteraction.present(animated: true, completionHandler: {
                        (pic, completed, error) in
                        if !completed && error != nil {
                            print("Error print could not be completed")
                        }
                    })
                }
            }
        }
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, emailButton button: UIButton!) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        if printInteraction != nil {
            printInteraction.dismiss(animated: true)
        }
        
        let fileSize = document.fileSize.uint64Value
        
        if fileSize < 15728640 { // check attachment size limit (15MB)
            let fileURL = document.fileURL
            let fileName = document.fileName
            var attachment: Data?
            do {
                attachment = try Data(contentsOf: fileURL!, options: [.dataReadingMapped,.uncached])
            } catch {
                print("Error with attachment")
            }
            if attachment != nil { // Ensure that we have a vlid document file attachment data available
                let mailComposer = MFMailComposeViewController()
                
                mailComposer.addAttachmentData(attachment!, mimeType: "application/pdf", fileName: fileName!)
                mailComposer.setSubject(fileName!) // Use the document file name for the subject
                
                mailComposer.modalTransitionStyle = .coverVertical
                mailComposer.modalPresentationStyle = .formSheet
                
                mailComposer.mailComposeDelegate = self //MFMailComposeViewControllerDelegate
                
                self.present(mailComposer, animated: true, completion: nil)
            }
        }
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, mark button: UIButton!) {
        if READER_BOOKMARKS {
            if printInteraction != nil {
                printInteraction.dismiss(animated: true)
            }
            
            if document.bookmarks.contains(currentPage) { // Remove bookmark
                document.bookmarks.remove(currentPage)
                mainToolbar.setBookmarkState(false)
            } else { // Add the bookmarked page number to the bookmark index set
                document.bookmarks.add(currentPage)
                mainToolbar.setBookmarkState(true)
            }
        }
    }
    
    func tapped(in toolbar: ReaderMainToolbar!, nameLabel label: UILabel!) {
        
    }
    
    
    // MFMailComposeViewControllerDelegate methods
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == MFMailComposeResult.failed && error != nil {
            print("Mail compose result failed")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    // DocumentInteractionControllerDelegate methods
    
    func thumbsViewController(_ viewController: ThumbsViewController!, gotoPage page: Int) {
        if READER_ENABLE_THUMBS {
            self.showDocumentPage(page)
        }
    }
    
    func dismiss(_ viewController: ThumbsViewController!) {
        if READER_ENABLE_THUMBS {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    // ReaderMainPagebarDelegate methods
    
    func pagebar(_ pagebar: ReaderMainPagebar!, gotoPage page: Int) {
        self.showDocumentPage(page)
    }
    
    // UIApplication notification methods
    
    func applicationWillResign(_ notification: Notification) {
        document.archiveDocumentProperties() // Save any ReaderDocument changes
        
        if userInterfaceIdiom == .pad {
            if printInteraction != nil {
                printInteraction.dismiss(animated: false)
            }
        }
    }
    
    
    
    
    
    
    
    
    
    /*   OLD IMPLEMENTATION
    
    var label: UILabel!
    var visible: Bool!
    var sheetTitle = "Title"

    override init!(readerDocument object: ReaderDocument!) {
        super.init(readerDocument: object)
        generalSetup()
    }
    
    init!(readerDocument object: ReaderDocument!, name: String) {
        super.init(readerDocument: object)
        sheetTitle = name
        generalSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        generalSetup()
    }
    
    func generalSetup(){
        visible = true
        let labelHeight: CGFloat = 30
        let labelWidth: CGFloat = 550
        let labelHeightOffs: CGFloat = 10
        
        label = UILabel(
            frame: CGRectMake((self.view.frame.size.width - labelWidth)/2 + 10, labelHeightOffs,
                labelWidth,labelHeight))
        label.font = UIFont(name: "Menlo-Bold", size: 20)
        label.backgroundColor = UIColor(white: 0.936, alpha: 1)
        label.textAlignment = .Center
        label.userInteractionEnabled = true
        label.text = sheetTitle
        
        //label touch recognizer
        let labelTapGestureRec = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        label.addGestureRecognizer(labelTapGestureRec)
        self.view.addSubview(label)
        
        //general touch recognizer
        /*
        let singleTapRec = UITapGestureRecognizer(target: self, action: #selector(tappedSheet(_:)))
        singleTapRec.requireGestureRecognizerToFail(labelTapGestureRec)
        singleTapRec.numberOfTapsRequired = 1
        singleTapRec.numberOfTouchesRequired = 1
        //singleTapRec.delegate = self
        self.view.addGestureRecognizer(singleTapRec)*/
        
    }
    
    func labelTapped(){
        print("Label tapped")
    }
    
    func tappedSheet(recognizer: UITapGestureRecognizer){
        let statusHeight: CGFloat = 44
        let tapPosition = recognizer.locationInView(recognizer.view)
        
        /*
        if tapPosition.y > statusHeight {
            print("= true")
        }*/
    }
 
 */
    
}
