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
    func dismissReaderViewController(viewController: SheetReaderViewController)
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
    
    var currentPage: Int!
    var minimumPage: Int!
    var maximumPage: Int!
    
    var documentInteraction: UIDocumentInteractionController!
    var printInteraction: UIPrintInteractionController!
    
    var scrollViewOutset: CGFloat!
    var lastAppearSize: CGSize!
    var lastHideTime: NSDate!
    
    var ignoreDidScroll: Bool!
    
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
    func updateContentSize(scrollView: UIScrollView){
        
        let contentHeight = scrollView.bounds.size.height   // Height
        let contentWidth = (scrollView.bounds.size.width * CGFloat(maximumPage))
        
        scrollView.contentSize = CGSizeMake(contentWidth, contentHeight)
    }
    
    func updateContentViews(scrollView: UIScrollView){
        
        self.updateContentSize(scrollView)  //Update content size first
        
        contentViews.enumerateKeysAndObjectsUsingBlock({  //Enumerate content views
            (key, contentView, stop) in
                let page = key.integerValue!  // Page numebr value
                var viewRect = CGRectZero
            
                viewRect.size = scrollView.bounds.size
                viewRect.origin.x = viewRect.size.width * (CGFloat(page) - 1) // Update X
            
                (contentView as! ReaderContentView).frame = CGRectInset(viewRect, self.scrollViewOutset, 0)
        })
        
        let page = currentPage
        let contentOffset = CGPointMake(scrollView.bounds.size.width * (CGFloat(page) - 1), 0)
        
        if(CGPointEqualToPoint(scrollView.contentOffset, contentOffset)){
            scrollView.contentOffset = contentOffset    // Update content offset
        }
        
        mainToolbar.setBookmarkState(document.bookmarks.containsIndex(page))
        mainPagebar.updatePagebar()  // Update page bar
    }
    
    func addContentView(scrollView: UIScrollView, page: Int){
        var viewRect = CGRectZero
        
        viewRect.size = scrollView.bounds.size
        viewRect.origin.x = (viewRect.size.width * (CGFloat(page) - 1))
        viewRect = CGRectInset(viewRect, self.scrollViewOutset, 0)
        
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
        
        contentView.message = self
        contentViews.setObject(contentView, forKey: page)
        scrollView.addSubview(contentView)
        
        // Request page preview thumb
        contentView.showPageThumb(fileURL, page: page, password: phrase, guid: guid)
    }
    
    func layoutContentViews(scrollView: UIScrollView){
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
        let pageSet = NSMutableIndexSet(indexesInRange: pageRange)
        
        //Enumerate content views
        for key: NSNumber in (contentViews.allKeys as! [NSNumber]) {
            let page = key.integerValue  // Page number value
            
            if !pageSet.containsIndex(page) {   // remove content view
                
                let contentView = contentViews.objectForKey(key)
                
                contentView?.removeFromSuperview()
                contentViews.removeObjectForKey(key)
            } else {    // visible contnet view - so remove it from page set
                pageSet.removeIndex(page)
            }
        }
        
        let pages = pageSet.count
        
        if pages > 0 {  // We have pages to add
            
            var options: NSEnumerationOptions = .Concurrent  // Default
            
            if pages == 2 { // Handle case of only two content views
                if (maximumPage > 2) && pageSet.lastIndex == maximumPage {
                    options = .Reverse
                }
            } else if (pages == 3) {  // Handle three content views - show the middle one first
                let workSet = pageSet.mutableCopy()
                options = .Reverse
                
                workSet.removeIndex(pageSet.firstIndex)
                workSet.removeIndex(pageSet.lastIndex)
                
                let page = workSet.firstIndex
                pageSet.removeIndex(page)
                
                self.addContentView(scrollView, page: page)
            }
            
            pageSet.enumerateIndexesWithOptions(options, usingBlock: {
                (page, stop) in
                    self.addContentView(scrollView, page: page)
            })
        }
    }
    
    func handleScrollViewDidEnd(scrollView: UIScrollView){
        let viewWidth = scrollView.bounds.size.width; // Scroll view width
        let contentOffsetX = scrollView.contentOffset.x; // Content offset X
        var page = Int(contentOffsetX / viewWidth) // Page number
        page += 1
        
        if page != currentPage { // Only if on different page
            currentPage = page
            document.pageNumber = page
            
            contentViews.enumerateKeysAndObjectsUsingBlock({ // Enumerate content views
                (key, contentView, stop) in
                    if key.integerValue != page {
                        contentView.zoomResetAnimated(false)
                    }
            })
            
            mainToolbar.setBookmarkState(document.bookmarks.containsIndex(page))
            mainPagebar.updatePagebar() // Update page bar
        }
    }
    
    func showDocumentPage(page: Int){
        
        if page != currentPage { // Only if on different page
            if page < minimumPage || page > maximumPage {
                return
            }
            
            currentPage = page
            document.pageNumber = page
            
            let contentOffset = CGPointMake((theScrollView.bounds.size.width * (CGFloat(page) - 1)), 0)
            
            if CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) {
                self.layoutContentViews(theScrollView)
            } else {
                theScrollView.setContentOffset(contentOffset, animated: false)
            }
            
            contentViews.enumerateKeysAndObjectsUsingBlock({
                (key, contentView, stop) in
                
                    if key.integerValue != page {
                        contentView.zoomResetAnimated(false)
                    }
            })
            
            mainToolbar.setBookmarkState(document.bookmarks.containsIndex(page))
            mainPagebar.updatePagebar()
        }
    }
    
    func showDocument(){
        self.updateContentSize(theScrollView)   // Update content size first
        self.showDocumentPage(document.pageNumber.integerValue) // Show page
        
        document.lastOpen = NSDate() // Update document last opened date
    }
    
    func closeDocument(){
        if printInteraction != nil {
            printInteraction.dismissAnimated(false)
        }
        
        document.archiveDocumentProperties() // save any ReaderDocument changes
        
        ReaderThumbQueue.sharedInstance().cancelOperationsWithGUID(document.guid)
        ReaderThumbCache.sharedInstance().removeAllObjects() // Empty the thumb cache
        
        delegate.dismissReaderViewController(self) // Dismiss the ReaderViewController
    }
    
    
    // UIViewController methods
    
    init(object: ReaderDocument?){
        super.init(nibName: nil, bundle: nil) // Initialize superclass
        
        if object != nil && (object?.isKindOfClass(ReaderDocument))!{ // Valid object
            
            userInterfaceIdiom = UIDevice.currentDevice().userInterfaceIdiom // User interface idiom
            
            let notificationCenter = NSNotificationCenter.defaultCenter() // Default notification center
            notificationCenter.addObserver(self, selector: #selector(SheetReaderViewController.applicationWillResign(_:)), name: UIApplicationWillTerminateNotification, object: nil)
            notificationCenter.addObserver(self, selector: #selector(SheetReaderViewController.applicationWillResign(_:)), name: UIApplicationWillResignActiveNotification, object: nil)
            
            if userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
                scrollViewOutset = SCROLLVIEW_OUTSET_LARGE
            } else {
                scrollViewOutset = SCROLLVIEW_OUTSET_SMALL
            }
            
            object?.updateDocumentProperties()
            document = object! // Retain the supplied ReaderDocument object for our use
            
            ReaderThumbCache.touchThumbCacheWithGUID(object?.guid) // Touch the document thumb cache directory
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(document != nil) // Must have a valid ReaderDocument
        
        self.view.backgroundColor = UIColor.grayColor() // Neutral grey
        
        var fakeStatusBar: UIView?
        var viewRect = self.view.bounds // View bounds
        
        //IOS 7+
        if !self.prefersStatusBarHidden() {
            var statusBarRect = viewRect
            statusBarRect.size.height = STATUS_HEIGHT
            fakeStatusBar = UIView(frame: statusBarRect) // UIView
            fakeStatusBar?.autoresizingMask = .FlexibleWidth
            fakeStatusBar?.backgroundColor = UIColor.blackColor()
            fakeStatusBar?.contentMode = .Redraw
            fakeStatusBar?.userInteractionEnabled = false
            
            viewRect.origin.y += STATUS_HEIGHT
            viewRect.size.height -= STATUS_HEIGHT
        }
        
        let scrollViewRect = CGRectInset(viewRect, -scrollViewOutset, 0)
        theScrollView = UIScrollView(frame: scrollViewRect) // All
        theScrollView.autoresizesSubviews = false
        theScrollView.contentMode = .Redraw
        theScrollView.showsHorizontalScrollIndicator = false
        theScrollView.showsVerticalScrollIndicator = false
        theScrollView.scrollsToTop = false
        theScrollView.delaysContentTouches = false
        theScrollView.pagingEnabled = true
        theScrollView.autoresizingMask = [.FlexibleWidth,.FlexibleHeight]
        theScrollView.backgroundColor = UIColor.clearColor()
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
        
        singleTapOne.requireGestureRecognizerToFail(doubleTapOne) // Single tap requires double tap to fail
        
        contentViews = NSMutableDictionary()
        lastHideTime = NSDate()
        
        minimumPage = 1
        maximumPage = document.pageCount.integerValue
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !CGSizeEqualToSize(lastAppearSize, CGSizeZero) {
            if !CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) {
                self.updateContentViews(theScrollView) // Update content views
            }
            
            lastAppearSize = CGSizeZero // Reset view size tracking
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) {
            self.performSelector(#selector(showDocument), withObject: nil, afterDelay: 0)
        }
        
        if READER_DISABLE_IDLE { // Option
            UIApplication.sharedApplication().idleTimerDisabled = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        lastAppearSize = self.view.bounds.size // Track view size
        if READER_DISABLE_IDLE {
            UIApplication.sharedApplication().idleTimerDisabled = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    /* ViewDidUnload deprecated starting at IOS 6*/
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if userInterfaceIdiom == .Pad {
            if printInteraction != nil {
                printInteraction.dismissAnimated(false)
            }
        }
        ignoreDidScroll = true
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        if !CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) {
            self.updateContentViews(theScrollView)
            lastAppearSize = CGSizeZero
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        ignoreDidScroll = false
    }
    
    override func didReceiveMemoryWarning() {
        //NSLog("%s",#function) // ONly when Debugging
        super.didReceiveMemoryWarning()
    }
    
    
    // UIScrollViewDelegate methods
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if !ignoreDidScroll {
            self.layoutContentViews(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.handleScrollViewDidEnd(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        self.handleScrollViewDidEnd(scrollView)
    }
    
    // UIGestureRecognizerDelegate methods
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if ((touch.view?.isKindOfClass(UIScrollView)) != nil) {
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
    
    func handleSingleTap(recognizer: UITapGestureRecognizer){
        if recognizer.state == UIGestureRecognizerState.Recognized {
            let viewRect = recognizer.view?.bounds // View bounds
            let point = recognizer.locationInView(recognizer.view) // Point
            let areaRect = CGRectInset(viewRect!, TAP_AREA_SIZE, 0) // Area rect
            
            if CGRectContainsPoint(areaRect, point) { // Single tap is inside area
                let key = currentPage // Page number key
                let targetView = contentViews.objectForKey(key) // View
                
                let target = targetView?.processSingleTap(recognizer) // Target object
                
                if target != nil { // Handle the returned target object
                    if target is NSURL  { // Open a URL
                        var url = target as! NSURL // cast to a NSURL object
                        
                        if !UIApplication.sharedApplication().canOpenURL(url) { // Handle a missing URL scheme
                            let www = url.absoluteString
                            if www.hasPrefix("www") { // Check for www prefix
                                let http = NSString(format: "http://%s", www)
                                url = NSURL(string: http as String)! // Proper http-based URL
                            }
                        }
                        
                        if !UIApplication.sharedApplication().openURL(url) {
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
                            mainToolbar.showToolbar()
                            mainPagebar.showPagebar()
                        }
                    }
                }
                return
            }
            
            var nextPageRect = viewRect!
            nextPageRect.size.width = TAP_AREA_SIZE
            nextPageRect.origin.x = (viewRect?.size.width)! - TAP_AREA_SIZE
            
            if CGRectContainsPoint(nextPageRect, point) { // page++
                self.incrementPageNumber()
                return
            }
            
            var prevPageRect = viewRect!
            prevPageRect.size.width = TAP_AREA_SIZE
            
            if CGRectContainsPoint(prevPageRect, point) { // page--
                self.decrementPageNumber()
                return
            }
        }
    }
    
    func handleDoubleTap(recognizer: UITapGestureRecognizer){
        if recognizer.state == UIGestureRecognizerState.Recognized {
            let viewRect = recognizer.view?.bounds // View bounds
            let point = recognizer.locationInView(recognizer.view) // Point
            let zoomArea = CGRectInset(viewRect!, TAP_AREA_SIZE, TAP_AREA_SIZE) // Area
            
            if CGRectContainsPoint(zoomArea, point) { // Double tap is inside zoom area
                let key = currentPage // Page number key
                let targetView = contentViews.objectForKey(key) // View
                
                switch recognizer.numberOfTapsRequired { // Touches count
                case 1: // One finger double tap: zoom++
                    targetView?.zoomIncrement(recognizer)
                    break
                case 2:
                    targetView?.zoomIncrement(recognizer)
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
            
            if CGRectContainsPoint(nextPageRect, point) { // Page++
                self.incrementPageNumber()
                return
            }
            
            var prevPageRect = viewRect!
            prevPageRect.size.width = TAP_AREA_SIZE
            
            if CGRectContainsPoint(prevPageRect, point) { // page--
                self.decrementPageNumber()
                return
            }
        }
    }
    
    
    // ReaderContentViewDelegate methods
    
    func contentView(contentView: ReaderContentView!, touchesBegan touches: Set<NSObject>!) {
        if mainToolbar.alpha > 0 || mainPagebar.alpha > 0 {
            if touches.count == 1 { // Single touches only
                let touch = touches?.first as? UITouch
                let point = touch?.locationInView(self.view)
                let areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE)
                
                if !CGRectContainsPoint(areaRect, point!) {
                    return
                }
                
                //Hide
                mainToolbar.hideToolbar()
                mainPagebar.hidePagebar()
                
                lastHideTime = NSDate() // Set last hide time
            }
        }
    }
    
    // ReaderMainToolbarDelegate methods
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, doneButton button: UIButton!) {
        if READER_STANDALONE {
            self.closeDocument() // Close ReaderViewController
        }
    }
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, thumbsButton button: UIButton!) {
        if READER_ENABLE_THUMBS {
            if printInteraction != nil {
                printInteraction.dismissAnimated(false)
            }
            
            let thumbsViewController = ThumbsViewController(readerDocument: document)
            
            thumbsViewController.title = self.title
            thumbsViewController.delegate = self // ThumbsViewControllerDelegate
            
            thumbsViewController.modalTransitionStyle = .CrossDissolve
            thumbsViewController.modalPresentationStyle = .FullScreen
            
            self.presentViewController(thumbsViewController, animated: false, completion: nil)
        }
    }
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, exportButton button: UIButton!) {
        if printInteraction != nil {
            printInteraction.dismissAnimated(true)
        }
        let fileURL = document.fileURL // Document file URL
        
        documentInteraction = UIDocumentInteractionController(URL: fileURL)
        documentInteraction.delegate = self // UIDOcumentINteractionControllerDelegate
        
        documentInteraction.presentOpenInMenuFromRect(button.bounds, inView: button, animated: true)
    }
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, printButton button: UIButton!) {
        if UIPrintInteractionController.isPrintingAvailable() {
            let fileURL = document.fileURL // Document dile URL
            
            if UIPrintInteractionController.canPrintURL(fileURL) {
                printInteraction = UIPrintInteractionController.sharedPrintController()
                
                let printInfo = UIPrintInfo.printInfo()
                printInfo.duplex = .LongEdge
                printInfo.outputType = .General
                printInfo.jobName = document.fileName
                
                printInteraction.printInfo = printInfo
                printInteraction.printingItem = fileURL
                printInteraction.showsPageRange = true
                
                if userInterfaceIdiom == .Pad { // Large device printing
                    printInteraction.presentFromRect(button.bounds, inView: button, animated: true, completionHandler: {
                        (pic, completed, error) in
                        if !completed && error != nil {
                            print("Error print could not be completed")
                        }
                    })
                } else { // Handle printing on small device
                    printInteraction.presentAnimated(true, completionHandler: {
                        (pic, completed, error) in
                        if !completed && error != nil {
                            print("Error print could not be completed")
                        }
                    })
                }
            }
        }
    }
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, emailButton button: UIButton!) {
        if !MFMailComposeViewController.canSendMail() {
            return
        }
        
        if printInteraction != nil {
            printInteraction.dismissAnimated(true)
        }
        
        let fileSize = document.fileSize.unsignedLongLongValue
        
        if fileSize < 15728640 { // check attachment size limit (15MB)
            let fileURL = document.fileURL
            let fileName = document.fileName
            var attachment: NSData?
            do {
                attachment = try NSData(contentsOfURL: fileURL, options: [.DataReadingMapped,.DataReadingUncached])
            } catch {
                print("Error with attachment")
            }
            if attachment != nil { // Ensure that we have a vlid document file attachment data available
                let mailComposer = MFMailComposeViewController()
                
                mailComposer.addAttachmentData(attachment!, mimeType: "application/pdf", fileName: fileName)
                mailComposer.setSubject(fileName) // Use the document file name for the subject
                
                mailComposer.modalTransitionStyle = .CoverVertical
                mailComposer.modalPresentationStyle = .FormSheet
                
                mailComposer.mailComposeDelegate = self //MFMailComposeViewControllerDelegate
                
                self.presentViewController(mailComposer, animated: true, completion: nil)
            }
        }
    }
    
    func tappedInToolbar(toolbar: ReaderMainToolbar!, markButton button: UIButton!) {
        if READER_BOOKMARKS {
            if printInteraction != nil {
                printInteraction.dismissAnimated(true)
            }
            
            if document.bookmarks.containsIndex(currentPage) { // Remove bookmark
                document.bookmarks.removeIndex(currentPage)
                mainToolbar.setBookmarkState(false)
            } else { // Add the bookmarked page number to the bookmark index set
                document.bookmarks.addIndex(currentPage)
                mainToolbar.setBookmarkState(true)
            }
        }
    }
    
    
    // MFMailComposeViewControllerDelegate methods
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        if result == MFMailComposeResultFailed && error != nil {
            print("Mail compose result failed")
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // DocumentInteractionControllerDelegate methods
    
    func thumbsViewController(viewController: ThumbsViewController!, gotoPage page: Int) {
        if READER_ENABLE_THUMBS {
            self.showDocumentPage(page)
        }
    }
    
    func dismissThumbsViewController(viewController: ThumbsViewController!) {
        if READER_ENABLE_THUMBS {
            self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    // ReaderMainPagebarDelegate methods
    
    func pagebar(pagebar: ReaderMainPagebar!, gotoPage page: Int) {
        self.showDocumentPage(page)
    }
    
    // UIApplication notification methods
    
    func applicationWillResign(notification: NSNotification) {
        document.archiveDocumentProperties() // Save any ReaderDocument changes
        
        if userInterfaceIdiom == .Pad {
            if printInteraction != nil {
                printInteraction.dismissAnimated(false)
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
