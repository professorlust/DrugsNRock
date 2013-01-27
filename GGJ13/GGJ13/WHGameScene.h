//
//  WHGameScene.h
//  JumpNPuke
//
//  Created by Alain Vagner on 15/02/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "BBAudioManager.h"
#import "WHPauseLayer.h"
//#import "WHControlLayer.h"
#import "WHGameLayer.h"
#import "GCDAsyncSocket.h"

#import "ObjectAL.h"
#import "OALAudioTrack.h"


#define MODE_SOLO 0
#define MODE_MULTI 1

@interface WHGameScene : CCScene {	
	int currentZique;
	int musicBPM;
	int gameBPM;
	int rivalBPM;
	int score;
}

@property (strong) WHGameLayer * gameLayer;
@property (strong) WHGameLayer * headerLayer;
@property (strong) WHPauseLayer * pauseLayer;
@property (strong) GCDAsyncSocket * socket;
@property (strong) NSMutableArray * ziques;


-(void) incrementBPM:(int)bpm;
-(void)showPauseLayer;
-(void)hidePauseLayer;
-(void) restartLevel;
-(int) getGameBPM;
-(void) updateJaugeWith:(int)statut;
-(void) sendDrug:(int)itemType;

+(WHGameScene *) scene:(int)m;


@end
