//
//  CvTMIDITuneViewController.h
//  CveTka
//
//  Created by tomaz stupnik on 9/4/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "../Spiral/CvTSpiralView.h"


@interface CvTMIDITuneViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@end


@interface CvTMIDITuneSelectViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *AllTunes;
}

@property (retain) CvTMIDITuneViewController *Parent;

@end