//
//  WHIntroLayer.mm
//  plop
//
//  Created by Alain Vagner on 04/01/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "WHIntroLayer.h"



// IntroBaseLayer implementation
@implementation WHIntroLayer

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	

	WHIntroLayer * baseLayer = [WHIntroLayer node];
	
	[scene addChild: baseLayer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
//		BBAudioManager *am = [BBAudioManager sharedAM];
//		[am preload];

		// initialisation de textures
//		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"ingame.plist"];
		
    }
    return self;
}

-(void) onEnter
{
	[super onEnter];

	// logo qui va s'animer
	CCSprite *logo = [CCSprite spriteWithFile:@"Default.png"];
	CGSize winsize = [[CCDirector sharedDirector] winSize];
	
	// fond d'écran
	
	logo.position = ccp(winsize.width/2 , winsize.height/2 );
	[self addChild:logo];

	
	// Pour éviter de saccader l'animation lors du chargement du son, on préload le son maintenant et on le schedule quand on veut.
	// Aussi, on unload le son dans la méthode dealloc (j'imagine
	// à noter également qu'il faut éviter les sons en wav et qu'il est facile de convertir en .caf… j'amènerai un script pour faire cette
	// conversion tt seule
	[self scheduleOnce:@selector(introSound:) delay:0.65];
	[self scheduleOnce:@selector(toNextScene:) delay:3.8];
}

- (void) toNextScene:(ccTime) dt {
    [[CCDirector sharedDirector] replaceScene: [CCTransitionFade transitionWithDuration:0.75f scene:[WHGameScene node]]];
}

- (void) introSound:(ccTime) dt {
    BBAudioManager *am = [BBAudioManager sharedAM];
	// play a sound here
}



@end
