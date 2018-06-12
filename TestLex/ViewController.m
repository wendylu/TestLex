//
//  ViewController.m
//  TestLex
//
//  Created by Wendy Lu on 12/10/17.
//  Copyright © 2017 Wendy Lu. All rights reserved.
//

#import "ViewController.h"

#import <AWSLex/AWSLexInteractionKit.h>

@interface ViewController () <AWSLexInteractionDelegate, AWSLexMicrophoneDelegate, AWSLexAudioPlayerDelegate>
@property (nonatomic, strong) AWSLexInteractionKit *interactionKit;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    self.spinner.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
    self.spinner.center = self.view.center;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.interactionKit = [AWSLexInteractionKit interactionKitForKey:@"USEast1InteractionKit"];
    self.interactionKit.microphoneDelegate = self;
    self.interactionKit.audioPlayerDelegate = self;
    self.interactionKit.interactionDelegate = self;
    [self.interactionKit audioInAudioOut];

}

#pragma mark AWSLexAudioPlayerDelegate

- (void)interactionKitOnAudioPlaybackStarted:(AWSLexInteractionKit *)interactionKit
{
    [self.spinner startAnimating];
}

- (void)interactionKitOnAudioPlaybackFinished:(AWSLexInteractionKit *)interactionKit
{
    [self.spinner stopAnimating];
}

#pragma mark AWSLexInteractionDelegate

- (void)interactionKit:(AWSLexInteractionKit *)interactionKit onError:(NSError *)error
{
    [self.interactionKit audioInAudioOut];
}

- (void)interactionKit:(AWSLexInteractionKit *)interactionKit onDialogReadyForFulfillmentForIntent:(NSString *)intentName slots:(NSDictionary *)slots
{
    NSLog(@"Intent fulfilled: %@", intentName); // logs “Intent fulfilled: NextStep” or “Intent fulfilled: PreviousStep”
}

- (void)interactionKit:(AWSLexInteractionKit *)interactionKit
       switchModeInput:(AWSLexSwitchModeInput *)switchModeInput
      completionSource:(AWSTaskCompletionSource<AWSLexSwitchModeResponse *> *)completionSource
{
    AWSLexSwitchModeResponse *switchModeResponse = [AWSLexSwitchModeResponse new];
    [switchModeResponse setInteractionMode:AWSLexInteractionModeSpeech];
    [switchModeResponse setSessionAttributes:switchModeInput.sessionAttributes];
    [completionSource setResult:switchModeResponse];
}

@end
