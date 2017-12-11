# TestLex

Amazon Lex is a service for building conversational interfaces into apps using voice and text. I recently integrated Lex into our iOS app as a part of a Hackathon project and realized how abysmal the docs are :( Here’s a Quick Start guide to help others like me who haven’t had much experience integrating with AWS in the past. 

1. Add the Lex SDK into you iOS app: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/setup-aws-sdk-for-ios.html.
I used Cocoapods and just added pod ‘AWSLex’ to my Podfile.

2. Create a Lex Bot on the web interface. Follow the “Getting Started” section of the Lex documentation: http://docs.aws.amazon.com/lex/latest/dg/getting-started.html

3. Once you have your Bot created, it’s time to create some Intents. An Intent is a particular goal the user wants to achieve. I’m making a hands free recipe interface that you control with your voice. I’d like to have my bot recognize “Next step” and “Previous step” to advance through the recipe. Create an Intent called “NextStep”.                                                       

Add some sample utterances to your intent. This is to let the bot know what user input it should look for. For the  NextStep intent, I added the following list of utterances: “Next Step”, “What’s next”, “Next”, and “Done”. 

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-09%20at%2011.37.31%20PM.png)

These are just sample phrases, so even if a user says something that doesn’t match exactly, the intent should still be recognized (i.e. “Go to next step”). This is one of the coolest parts of this SDK, and what really made it worth using for me!

Enter “Slots” if you need the user to provide additional information before the intent is fulfilled. We won’t do this in this example since we simply need to recognize “Next Step” and “Previous Step”.

In the “Fulfillment” section, select “Return parameters to client”. We assume that our iOS app will handle the business logic after Lex recognizes an intent.

Save the Intent when you are done.

4. Create another Intent (within the same Bot), for the previous step navigation.

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-09%20at%2011.35.57%20PM.png)

Hit “Build” on the top right of the screen. You can then test out your Lex Bot through the “Test Chatbot” panel on the right side of the screen. 

![Image](https://github.com/wendylu/images/raw/081fd9db6627ac4c3babaf35e469d787a8080cde/Screen%20Shot%202017-12-09%20at%2011.31.11%20PM.png)

5. Next, we’ll connect our iOS app with our Lex Bot. AWS authentication can be a bit complex if you haven’t done it before. First, In the Amazon Cognito Console, select “Manage Federated Identities”

6. Choose “Create a new identity pool”. Enter in the desired name for your identity pool, i.e. “TestLex”. 

For testing, check “Enable access to unauthenticated identities”. This allows your app to assume the unauthenticated role associated with this identity pool. You can come back later and add a Authentication Provider if you only want to allow users to use Lex when logged in. This is most likely the best practice, but for testing, we’ll just use an unauthenticated role.

7. In the next step, Cognito will setup two roles in Identity and Access Management (IAM). Here they are named “Cognito_TestLexAuth_Role” and “Cognito_TestLexUnauth_Role”. 

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-10%20at%2012.02.11%20AM.png)

These roles define what permissions and services your users can access. You can get back to find these roles by tapping “Edit Identity Pool” on your Identity Pool dashboard.

8. We need to add Lex permission to the unauthenticated role.

Create an IAM Policy in the IAM Console. In the creation flow, select “Service” and add the Lex Service. 

Select “All Lex Actions” under Actions

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-10%20at%2012.07.13%20AM.png)

Under Resources, select “All Resources”

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-10%20at%2012.07.55%20AM.png)

Review and create the policy.

9. Go to “Roles” on the sidebar of the IAM Console. Click on the unauthenticated role of your identify pool (Cognito_TestLexUnauth_Role) and attach the policy you just created to the role.

10. Under “Sample code” in your identity pool page, you can see how to initialize your credentials on various platforms. Copy the Objective C or Swift version of the code and add it to your AppDelegate. We are *finally* ready to start writing iOS code!

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize the Amazon Cognito credentials provider
 
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                          initWithRegionType:AWSRegionUSEast1
                                                          identityPoolId:@"your-pool-id"];
 
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast1 credentialsProvider:credentialsProvider];
 
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
 
    return YES;
}
```

11. Also in application:didFinishLaunchingWithOptions:, initialize the interaction kit for your bot. You can set the bot alias by clicking “Publish” on the Bot page, and find existing aliases with “Settings”->”Aliases”.

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-10%20at%206.37.07%20PM.png)

```objective-c
AWSLexInteractionKitConfig *config = [AWSLexInteractionKitConfig defaultInteractionKitConfigWithBotName:@"RecipeBot" botAlias:@"Prod"];
// 5000 seconds before timeout
config.noSpeechTimeoutInterval = 5000;
config.maxSpeechTimeoutInterval = 5000;
 
 // We will use this key to retrieve the interaction kit in our view controller
[AWSLexInteractionKit registerInteractionKitWithServiceConfiguration:configuration interactionKitConfiguration:config forKey:@"USEast1InteractionKit"];
```

12. Listen for input. Amazon Lex does not support wake word functionality (i.e. “Hey Alexa…”). Our app is responsible for letting the interaction kit know when to start listening.

There are 4 methods on AWSLexInteractionKit to specify how we want to interact with the Lex Bot. For our app, we want to take in audio input and play audio output, so we use audioInAudioOut.  
The other 3 options are audioInTextOut, textInTextOut, and textInAudioOut.

In the viewDidAppear method of my main view controller, I get the interaction kit and start listening for audio input.
 
```objective-c
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
 
    self.interactionKit = [AWSLexInteractionKit interactionKitForKey:@"USEast1InteractionKit"];
    self.interactionKit.microphoneDelegate = self;
    self.interactionKit.audioPlayerDelegate = self;
    self.interactionKit.interactionDelegate = self;
    [self.interactionKit audioInAudioOut];
}
```

13. Set a NSMicrophoneUsageDescription in your Info.plist.

14. There are various delegate methods on AWSLexMicrophoneDelegate
, AWSLexAudioPlayerDelegate, and AWSLexInteractionDelegate that you can hook into. For example, we can use the following delegate methods to show a loading state while Lex is speaking to us.

```objective-c
- (void)interactionKitOnAudioPlaybackStarted:(AWSLexInteractionKit *)interactionKit
{
    [self.spinner startAnimating];
}
 
- (void)interactionKitOnAudioPlaybackFinished:(AWSLexInteractionKit *)interactionKit
{
    [self.spinner stopAnimating];
}
```

15. Error handling: When Lex doesn’t recognize an input, it will output a clarification phrase. The default is “Sorry, can you please repeat that?”. You can configure this phrase, as well as the max number of retries, in “Error handling” section on the web console.

Lex only allows 5 maximum retries until it hangs up and stops listening. I wanted to keep listening until I received a valid utterance, so I set both the Clarification Prompt and Hang-up Phrase to “Listening”

![Image](https://github.com/wendylu/images/raw/master/Screen%20Shot%202017-12-10%20at%209.24.07%20PM.png)

And then restarted listening on interactionKit:onError, which gets called when Lex hangs up.

```objective-c
- (void)interactionKit:(AWSLexInteractionKit *)interactionKit onError:(NSError *)error
{
    [self.interactionKit audioInAudioOut];
}
```

16. Implement the following delegate method to resume listening when Lex finishes speaking:

```objective-c
- (void)interactionKit:(AWSLexInteractionKit *)interactionKit
       switchModeInput:(AWSLexSwitchModeInput *)switchModeInput
      completionSource:(AWSTaskCompletionSource<AWSLexSwitchModeResponse *> *)completionSource
{
    AWSLexSwitchModeResponse *switchModeResponse = [AWSLexSwitchModeResponse new];
    [switchModeResponse setInteractionMode:AWSLexInteractionModeSpeech];
    [switchModeResponse setSessionAttributes:switchModeResponse.sessionAttributes];
    [completionSource setResult:switchModeResponse];
}
```

17.  When Lex has recognized the utterance and is ready to fulfill the intent, the following method will be called. We can then use the intentName and the slots dictionary for our app’s business logic. 

```objective-c
- (void)interactionKit:(AWSLexInteractionKit *)interactionKit onDialogReadyForFulfillmentForIntent:(NSString *)intentName slots:(NSDictionary *)slots
{
    NSLog(@"Intent fulfilled: %@", intentName); // logs “Intent fulfilled: NextStep” or “Intent fulfilled: PreviousStep”
}
```




