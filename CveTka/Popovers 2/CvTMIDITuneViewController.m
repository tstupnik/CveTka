//
//  CvTMIDITuneViewController.m
//  CveTka
//
//  Created by tomaz stupnik on 9/4/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTMIDITuneViewController.h"
#import "../Airplay/CvTPlayback.h"


@implementation CvTMIDITuneSelectViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    AllTunes = [[NSMutableArray alloc] init];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"potocek postoj in povej", @"potocek", @3, @69, @0, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"mamica je kakor zarja", @"mamica", @1, @57, @0, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"tam kjer murke cveto", @"murke", @5, @57, @0, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"spanish twostep", @"twostep", @5, @57, @0, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"greensleeves", @"greensleeves", @8, @57, @9, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"bombay dog", @"bombaydog", @3, @57, @2, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"autumn leaves", @"autumnleaves", @10, @45, @9, @"101011010101"]]];
    [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithArray:@[@"grawel walk", @"grawelwalk", @10, @57, @2, @"101011010101"]]];
    
    NSString *dirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE) objectAtIndex:0];
    NSArray *files = [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:NULL] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.mid'"]];
    
    for (NSString *file in files)
        [AllTunes addObject:[[CvTMidiTuneInfo alloc] initWithFile:file]];

    return [super initWithCoder:aDecoder];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return AllTunes.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
    if (cell == NULL)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    CvTMidiTuneInfo *tuneInfo = AllTunes[indexPath.row];
    cell.textLabel.text = tuneInfo.Name ? tuneInfo.Name : tuneInfo.File;
    if ([tuneInfo.File isEqualToString:[CvTPlaybackThread Playback].SelectedFile.File])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    @try{
        cell.tintColor = [UIColor blueColor];
    } @catch (NSException*) {}
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    for (UITableViewCell *cell in tableView.visibleCells)
        cell.accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [CvTPlaybackThread Playback].SelectedFile = AllTunes[indexPath.row];
}

@end


@implementation CvTMIDITuneViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    return [super initWithCoder:aDecoder];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"MIDI Tune"];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section ? 1 : 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
    if (cell == NULL)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    switch (indexPath.section * 2 + indexPath.row)
    {
        case 0: cell.textLabel.text = @"Select";
            cell.detailTextLabel.text = [CvTPlaybackThread Playback].SelectedFile.File;
            break;
        case 1: cell.textLabel.text = @"New";
            break;
        case 2:
            cell.textLabel.text = @"Send";
            break;
    }
    return cell;
}

-(void)viewWillAppear:(BOOL)animated
{
    [((UITableView*)self.view) reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0)
        {
            [self performSegueWithIdentifier:@"Select" sender:self];
        }
        else
        {
            [CvTPlaybackThread Playback].SelectedFile = NULL;
            [tableView reloadData];
        }
    }
    else
    {
        if ([MFMailComposeViewController canSendMail])
        {
            MFMailComposeViewController  *controller = [[MFMailComposeViewController alloc] init];
            if (controller)
            {
                controller.mailComposeDelegate = self;
                [controller setSubject:@"CveTka recording"];
                [controller setToRecipients:[NSArray arrayWithObjects:@"tomaz.stupnik@guest.arnes.si", nil]];
                [controller addAttachmentData:[[CvTRecorder Recorder] Save:NULL] mimeType:@"audio/midi" fileName:@"mytune"];
                [controller setMessageBody:@"I have just recorded this tune!" isHTML:FALSE];
                
                [self presentViewController:controller animated:TRUE completion:NULL];
            }
            
            /*NSData *data = [_Spiral.Synth.AirplayJam.Recorder Save];
             
             NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, TRUE) objectAtIndex:0] stringByAppendingString:@"mytune.mid"];
             [data writeToFile:filePath atomically:TRUE];
             
             UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:filePath]] applicationActivities:NULL];
             if (controller)
             [self presentViewController:controller animated:TRUE completion:NULL];*/
        }
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
     if ([segue.identifier isEqualToString:@"Select"])
         ((CvTMIDITuneSelectViewController *)[segue destinationViewController]).Parent = self;
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:TRUE completion:NULL];
}

@end
