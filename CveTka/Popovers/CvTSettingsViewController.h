//
//  CvTSettingsViewController.h
//  CveTka
//
//  Created by tomaz stupnik on 9/1/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CvTCustomSettingsViewController : UIViewController
@property (retain) id delegate;
@end


@interface CvTAirplaySettingsViewController : CvTCustomSettingsViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *Airplay;
@property (weak, nonatomic) IBOutlet UISegmentedControl *AirplaySymbol;
@property (weak, nonatomic) IBOutlet UILabel *Status;
@end


@interface CvTPersonalitySettingsViewController : CvTCustomSettingsViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *Personality;
@end


@interface CvTAutotuneSettingsViewController : CvTCustomSettingsViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *AutotuneTime;
@property (weak, nonatomic) IBOutlet UISegmentedControl *Autotune;
@end


@interface CvTRootSettingsViewController : CvTCustomSettingsViewController
@property (weak, nonatomic) IBOutlet UISegmentedControl *UpperTones;
@property (weak, nonatomic) IBOutlet UISegmentedControl *LowerTones;
@property (weak, nonatomic) IBOutlet UISegmentedControl *Pitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *ConcertPitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *Intonation;
@end


@interface CvTSettingsTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate>
@property (retain) id delegate;
@property (assign) NSDictionary *Values;
@property (assign) NSString *Title;
@property (retain) id SelectedValue;
@end


@protocol CvTTableViewControllerDelegate <NSObject>

@required
-(void)didFinishDetail:(id)viewController;

@end


@interface CvTSettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, CvTTableViewControllerDelegate>
{
    NSDictionary *TimeSignatures;
    NSDictionary *Tempos;
    NSDictionary *Sounds;
}

@end