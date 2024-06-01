//
//  CvTSettingsViewController.m
//  CveTka
//
//  Created by tomaz stupnik on 9/1/14.
//  Copyright (c) 2014 Godalkanje. All rights reserved.
//

#import "CvTSettingsViewController.h"
#import "../Spiral/CvTSpiralView.h"
#import "../CvTAppSettings.h"
#import "../CvTViewController.h"

@implementation CvTCustomSettingsViewController

-(void)viewWillDisappear:(BOOL)animated {
    if (_delegate)
        [_delegate didFinishDetail:self];
}

@end


@implementation CvTAirplaySettingsViewController

-(void)viewDidLoad
{
    [self setTitle:@"Airplay"];
    [_Airplay setSelectedSegmentIndex:[CvTAppSettings Current].Airplay];
    [_AirplaySymbol setSelectedSegmentIndex:[CvTAppSettings Current].AirplaySymbol];
}

- (IBAction)AirplayChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].Airplay = (int)[sender selectedSegmentIndex];
    [CvTAirplayJam AirplayJam].Mode = [CvTAppSettings Current].Airplay;
}

- (IBAction)AirplaySymbolChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].AirplaySymbol = (int)[sender selectedSegmentIndex];
}

@end


@implementation CvTPersonalitySettingsViewController

-(void)viewDidLoad
{
    [self setTitle:@"Personality"];
    [_Personality setSelectedSegmentIndex:[CvTAppSettings Current].Personality];
}

- (IBAction)PersonalityChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].Personality = (int)[sender selectedSegmentIndex];
    [(CvTViewController*)[CvTSpiralView Spiral].window.rootViewController applicationDidBecomeActive];
}

@end


@implementation CvTAutotuneSettingsViewController

-(void)viewDidLoad
{
    [self setTitle:@"Autotune"];
    [_Autotune setSelectedSegmentIndex:[CvTAppSettings Current].AutoTune];
    [_AutotuneTime setSelectedSegmentIndex:[CvTAppSettings Current].AutoTuneTime];
}

- (IBAction)AutotuneTimeChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].AutoTuneTime = (int)[sender selectedSegmentIndex];
}

- (IBAction)AutotuneChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].AutoTune = (int)[sender selectedSegmentIndex];
}

@end


@implementation CvTRootSettingsViewController

-(void)viewDidLoad
{
    [self setTitle:@"Root"];
    
    int root = [CvTAppSettings Current].RootTone;
    [_UpperTones setSelectedSegmentIndex:(root < 6) ? root : -1];
    [_LowerTones setSelectedSegmentIndex:(root >= 6) ? (root - 6) : -1];
    
    for (int i = 0; i < 6; i++)
    {
        [_LowerTones setTitle:[CvTScale MidiToneName:57 + 6 + i] forSegmentAtIndex:i];
        [_UpperTones setTitle:[CvTScale MidiToneName:57 + i] forSegmentAtIndex:i];
    }
    
    switch ([CvTAppSettings Current].RootOctave)
    {
        case kSynthRootOctave_Bass:
            [_Pitch setSelectedSegmentIndex:0];
            break;
        case kSynthRootOctave_Alt:
            [_Pitch setSelectedSegmentIndex:1];
            break;
        default:
            [_Pitch setSelectedSegmentIndex:2];
    }
    
    [_ConcertPitch setSelectedSegmentIndex:[CvTAppSettings Current].ConcertPitch - 440];
    [_Intonation setSelectedSegmentIndex:[CvTAppSettings Current].Intonation];
}

- (IBAction)UpperTonesChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].RootTone = (int)[sender selectedSegmentIndex];
    [_LowerTones setSelectedSegmentIndex:-1];
}

- (IBAction)LowerTonesChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].RootTone = 6 + (int)[sender selectedSegmentIndex];
    [_UpperTones setSelectedSegmentIndex:-1];
}

- (IBAction)PitchChange:(UISegmentedControl *)sender {
    switch ([sender selectedSegmentIndex])
    {
        case 0:
            [CvTAppSettings Current].RootOctave = kSynthRootOctave_Bass;
            break;
        case 1:
            [CvTAppSettings Current].RootOctave = kSynthRootOctave_Alt;
            break;
        default:
            [CvTAppSettings Current].RootOctave = kSynthRootOctave_Soprano;
    }
}

- (IBAction)ConcertPitchChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].ConcertPitch = [_ConcertPitch selectedSegmentIndex] + 440.0f;
}
- (IBAction)IntonationChange:(UISegmentedControl *)sender {
    [CvTAppSettings Current].Intonation = [_Intonation selectedSegmentIndex];
}

@end


@implementation CvTSettingsTableViewController

-(void)viewDidLoad {
    [self setTitle:_Title];
}

-(void)viewWillDisappear:(BOOL)animated {
    if (_delegate)
        [_delegate didFinishDetail:self];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _Values.count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSArray*)AllKeys {
    return [[_Values allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == NULL)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    id key = self.AllKeys[indexPath.row];
    if ([key isEqualToValue:_SelectedValue])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        
    cell.textLabel.text = [_Values objectForKey:key];
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
    _SelectedValue = self.AllKeys[indexPath.row];
}

@end


@implementation CvTSettingsViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    TimeSignatures = [@{ [NSNumber numberWithInt:kMetronomeTimeSignature_2_4]:@"2/4",
                         [NSNumber numberWithInt:kMetronomeTimeSignature_3_4]:@"3/4",
                         [NSNumber numberWithInt:kMetronomeTimeSignature_4_4]:@"4/4",
                         [NSNumber numberWithInt:kMetronomeTimeSignature_5_4]:@"5/4" } copy];
    
    Tempos = [NSDictionary dictionaryWithObjectsAndKeys: @"60", @60, @"80", @80, @"100", @100, @"120", @120, @"140", @140, @"160", @160, @"180", @180, @"200", @200, @"220", @220, nil];
    
    Sounds = [@{    [NSNumber numberWithInt:kSynthSound_Midi]:@"MIDI",
                    [NSNumber numberWithInt:kSynthSound_Pluck]:@"pluck",
                    [NSNumber numberWithInt:kSynthSound_Ping]:@"Ping",
                    [NSNumber numberWithInt:kSynthSound_Pong]:@"Pong" } copy];
    
    return [super initWithCoder:aDecoder];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self setTitle:@"Settings"];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? 4 : ((section == 1) ? 2 : 1);
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @" ";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@""];
    if (cell == NULL)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@""];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if (indexPath.section == 0)
        switch(indexPath.row)
    {
        case 0: cell.textLabel.text = @"Sound";
            cell.detailTextLabel.text= [Sounds objectForKey:[NSNumber numberWithInt:[CvTAppSettings Current].Sound]];
            break;
        case 1:
            cell.textLabel.text = @"Scale";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%d", [CvTScale MidiToneName:(57 + [CvTAppSettings Current].RootTone)], (int)([CvTAppSettings Current].RootOctave - 69 + 48) / 12];
            break;
        case 2:
            cell.textLabel.text = @"Autotune";
            switch ([CvTAppSettings Current].AutoTuneTime)
        {
            case kAutoTuneSpeed_Fast: cell.detailTextLabel.text = @"Fast";
                break;
            case kAutoTuneSpeed_Snap: cell.detailTextLabel.text = @"Snap";
                break;
            case kAutoTuneSpeed_Slow: cell.detailTextLabel.text = @"Slow";
                break;
            default: cell.detailTextLabel.text = @"None";
        }
            break;
        case 3:
            cell.textLabel.text = @"Airplay";
            //cell.detailTextLabel.text = @"Connected";
            break;
    }
    if (indexPath.section == 1)
        switch (indexPath.row)
    {
        case 0: cell.textLabel.text = @"Tempo";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", [CvTAppSettings Current].Tempo];
            break;
        case 1:
            cell.textLabel.text = @"Time Signature";
            cell.detailTextLabel.text= [TimeSignatures objectForKey:[NSNumber numberWithInt:[CvTAppSettings Current].TimeSignature]];
            break;
    }
    if (indexPath.section == 2)
        switch (indexPath.row)
    {
        case 0: cell.textLabel.text = @"Personality";
            switch ([CvTAppSettings Current].Personality)
        {
            case kAppPersonality_Bach: cell.detailTextLabel.text = @"Bach";
                break;
            case kAppPersonality_Sibelius: cell.detailTextLabel.text = @"Sibelius";
                break;
            default: cell.detailTextLabel.text = @"Dvorak";
        }
            break;
    }
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[segue destinationViewController] setValue:self forKeyPath:@"delegate"];
    
    if ([segue.identifier isEqualToString:@"Sound"])
    {
        CvTSettingsTableViewController *controller = [segue destinationViewController];
        controller.Title = @"Sound";
        controller.Values = Sounds;
        controller.SelectedValue = [NSNumber numberWithInt:[CvTAppSettings Current].Sound];
    }
    if ([segue.identifier isEqualToString:@"TimeSignature"])
    {
        CvTSettingsTableViewController *controller = [segue destinationViewController];
        controller.Title = @"Time Signature";
        controller.Values = TimeSignatures;
        controller.SelectedValue = [NSNumber numberWithInt:[CvTAppSettings Current].TimeSignature];
    }
    if ([segue.identifier isEqualToString:@"Tempo"])
    {
        CvTSettingsTableViewController *controller = [segue destinationViewController];
        controller.Title = @"Tempo";
        controller.Values = Tempos;
        controller.SelectedValue = [NSNumber numberWithInt:[CvTAppSettings Current].Tempo];
    }
}

-(void)didFinishDetail:(id)viewController
{
    if ([viewController isKindOfClass:[CvTSettingsTableViewController class]])
    {
        CvTSettingsTableViewController *tableViewController = (CvTSettingsTableViewController*)viewController;
        if ([tableViewController.Values isEqual:Sounds])
            [[CvTSynth Synth] LoadPreset:([CvTAppSettings Current].Sound = [tableViewController.SelectedValue intValue])];
        if ([tableViewController.Values isEqual:TimeSignatures])
            [CvTAppSettings Current].TimeSignature = [tableViewController.SelectedValue intValue];
        if ([tableViewController.Values isEqual:Tempos])
            [CvTAppSettings Current].Tempo = [tableViewController.SelectedValue intValue];
    }
    [[CvTSpiralView Spiral] Initialize];
    
    UITableView *tableView;
    for (id view in self.view.subviews)
        if ([view isKindOfClass:[UITableView class]])
            tableView = (UITableView*)view;
    if (tableView)
        [tableView reloadData];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *segueNames[] = { @"Sound", @"Root", @"Autotune", @"Airplay", @"Tempo", @"TimeSignature", @"Personality"};
    [self performSegueWithIdentifier:segueNames[((indexPath.section == 1) ? 4 : 0) + ((indexPath.section == 2) ? 6 : 0) + indexPath.row] sender:self];
}

@end
