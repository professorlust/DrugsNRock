//
//  WHGameLayer.m
//  
//
//  Created by Biou on 28/12/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//


// Import the interfaces
#import "WHGameLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"

#import "WHGameScene.h"


#define HIT_Y 50.0f
#define HIT_TOLERANCE 30.0f
#define PERFECT_TOLERANCE 8.0f
#define SEUIL_TROP_TARD 15.0f
#define MAX_DURATION 8.0f
#define BPM_MEDIAN 125

#define RECORDING_MODE NO


// HelloWorldLayer implementation
@implementation WHGameLayer
{
	

    float _elapsedTime;
    int _currentMusicBPM;
    BOOL flip;
    BOOL _lastActionSuccess;
    int _jaugeSucces;
    int _jaugeEchecs;
    BOOL _shouldSendDrugToOpponent;
}

@synthesize gcdQueue;

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init]) ) {
		gcdQueue = dispatch_queue_create("org.sous-anneau.dnrqueue", NULL);
		
        // init des variables
        self.activeItems = [NSMutableArray new];
        _jaugeEchecs = 0;
        _jaugeSucces= 0;
        
		// initialisation de textures
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"spritesheet.plist"];
        
        // Layer de contrôle
        WHControlLayer *ctrl = [WHControlLayer node];
        ctrl.gameLayer = self;
        [self addChild:ctrl];
        
        _currentMusicBPM = 0;
        _elapsedTime = 0.0;
		_reverse = NO;

        
        // éléments utiles uniquement pour enregistrer une partoche
#ifdef RECORDING_MODE
        [self initRecording];
#endif
        
        // init du tick
        [self schedule: @selector(tick:) interval:1.0/30.0];
        
        // Boutons de jeu
		self.boutons = [NSMutableArray arrayWithCapacity:4];
        CCSprite *bouton = [CCSprite spriteWithSpriteFrameName:@"bouton-off.png"];
        bouton.position = ccp(40, 60);
        [self addChild:bouton];
        [self.boutons addObject:bouton];
        
        bouton = [CCSprite spriteWithSpriteFrameName:@"bouton-off.png"];
        bouton.position = ccp(120, 60);
        [self addChild:bouton];
        [self.boutons addObject:bouton];
        
        bouton = [CCSprite spriteWithSpriteFrameName:@"bouton-off.png"];
        bouton.position = ccp(200, 60);
        [self addChild:bouton];
        [self.boutons addObject:bouton];
        
        bouton = [CCSprite spriteWithSpriteFrameName:@"bouton-off.png"];
        bouton.position = ccp(280, 60);
        [self addChild:bouton];
        [self.boutons addObject:bouton];
	}
	return self;
}


-(void) tick: (ccTime) dt
{
    _elapsedTime+=dt;
    while ([self.partition nextItemTimestamp] != 0.0 && _elapsedTime > [self.partition nextItemTimestamp] - [self adjustedDuration]*(0.82f+_currentMusicBPM*0.01)) {
        // NSLog(@"New Item");
        [self newItem:ItemTypeNormal atLane:[self.partition itemLane]];
        [self.partition goToNextItem];
    }

    if ([self.partition nextItemTimestamp] == 0.0f) {
        [self scheduleOnce:@selector(forceRestart) delay:[self adjustedDuration]+0.2f];

    }

    if ([self.activeItems count]>0){
        WHItem *item = (WHItem *)[self.activeItems objectAtIndex:0];
        if(item.position.y >HIT_Y-2 && item.position.y <HIT_Y+2) {
            // NSLog(@"########## First point -- y:%f temps:%f",item.position.y,_elapsedTime);
        }
        
        NSMutableArray *gc = [NSMutableArray new];
		dispatch_sync(gcdQueue, ^{
			for (WHItem *i in self.activeItems) {
				if(i.position.y<SEUIL_TROP_TARD) {
					[gc addObject:i];
					if (i.type == ItemTypeNormal) {
						[self itemMissed:NO];
					}
//                if (i.specialPeer != nil) {
//                    [gc addObject:i.specialPeer];
//                }
				}
			}
		});
		dispatch_sync(gcdQueue, ^{
         for (WHItem *i in gc) {
             [self.activeItems removeObject:i];
             [self removeChild:i cleanup:YES];
         }
		});
    }
}

-(void)forceRestart {
    [self.gameScene executeNewZique];
}


-(void) newItem:(ItemType)itemType atLane: (int)itemLane
{
    BOOL weWantSpecialItem = NO;
    float proba = MIN(20.0f + _elapsedTime,60.0f)/60.0f;
    float rand = ((float)arc4random())/100000.0f;
    rand -= floorf(rand);
    weWantSpecialItem = rand < proba;
    
    WHItem *itemSprite = [WHItem spriteWithSpriteFrameName:@"neutre.png"];
    
    CGSize winsize = [[CCDirector sharedDirector] winSize];
    itemSprite.position = ccp(40.0f+80*(itemLane), winsize.height + 50);
    [self addChild:itemSprite];
	dispatch_sync(gcdQueue, ^{
		[self.activeItems addObject:itemSprite];
	});
    // NSLog(@"Ligne de nouvel élément: %d", itemLane);
    
    if (weWantSpecialItem) {
        WHItem *specialItemSprite = [WHItem randomSpecialItem];
        itemLane += flip?5:3;
        flip=!flip;
        specialItemSprite.position = ccp(40.0f+80*(itemLane%4), winsize.height + 50);
        [self addChild:specialItemSprite];
        [self.activeItems addObject:specialItemSprite];
        
        // NSLog(@"Ligne d’élément spécial: %d", itemLane);
        
        itemSprite.specialPeer = specialItemSprite;
        specialItemSprite.specialPeer = itemSprite;
        
        // Create the actions
        id actionMove2 = [CCMoveTo actionWithDuration:[self adjustedDuration] position:ccp(specialItemSprite.position.x, -50)];
        // id actionMoveDone2 = [CCCallFuncN actionWithTarget:self selector:@selector(itemMoveFinished:)];
        [specialItemSprite runAction:[CCSequence actions:actionMove2, nil, nil]];
        
        // Create fade in action
        id actionFadeIn = [CCFadeIn actionWithDuration:[self adjustedDuration]*0.44f];
        [specialItemSprite runAction:actionFadeIn];
    }
    

    
    // Create the actions
    id actionMove = [CCMoveTo actionWithDuration:[self adjustedDuration] position:ccp(itemSprite.position.x, -50)];
    // id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(itemMoveFinished:)];
    [itemSprite runAction:[CCSequence actions:actionMove, nil, nil]];
    
    
    // Create fade in action
    id actionFade = [CCFadeIn actionWithDuration:[self adjustedDuration]*0.44f];
    [itemSprite runAction:actionFade];
    
}

-(void)itemFadeFinished:(id)target {
    
}

-(void)itemMoveFinished:(id)target
{
    // NSLog(@"Fin de move… Suppr. de l’item");
    CCNode *node = (CCNode *)[self.activeItems objectAtIndex:0];
    [self.activeItems removeObjectAtIndex:0];
    [self removeChild:node cleanup:YES];
}

-(void)touchBoutonX: (float)bx withNumber: (int)n
{
    NSArray *items = [self.activeItems copy];
    BOOL hit = NO;
    WHItem *hittedItem;
    for (WHItem *item in items) {
        // todo : comparer les coordonnées.
        float y = item.position.y;
        float x = item.position.x;
        if (y>HIT_Y-HIT_TOLERANCE && y <HIT_Y+HIT_TOLERANCE && x>bx-HIT_TOLERANCE && x<bx+HIT_TOLERANCE) {
            hit = YES;
            hittedItem = item;
            break;
        }
    }

    if(hit) {
        // NSLog(@"Hit!: %d", n);
        [self itemTapped:hittedItem];
		[[self.boutons objectAtIndex:n] setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"bouton-on-yes.png"]];
		// NSLog(@"%@", self.boutons);
    } else {
		[[self.boutons objectAtIndex:n] setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"bouton-on-no.png"]];
		BBAudioManager * am = [BBAudioManager sharedAM];
		
		[self.gameScene incrementScore:-5];
		[am playSFX:@"buzz.caf"];
		[self itemMissed:YES];
    }
}

-(void)restoreBouton:(int)btn {
	[[self.boutons objectAtIndex:btn] setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"bouton-off.png"]];
}

-(void)touchBouton:(int)boutonNb
{
    switch (boutonNb) {
        case 0:
            [self touchBoutonX:40 withNumber:0];
            break;
            
        case 1:
            [self touchBoutonX:120 withNumber:1];
            break;
            
        case 2:
            [self touchBoutonX:200 withNumber:2];
            break;
            
        case 3:
            [self touchBoutonX:280 withNumber:3];
            break;
            
        default:
            break;
    }
	
#ifdef RECORDING_MODE
    NSTimeInterval dt = -[self.dateInit timeIntervalSinceNow];
    [self.recPartition.array addObject:@[[NSNumber numberWithDouble:dt],[NSNumber numberWithInt:boutonNb]]];
     
     // NSLog(@"touch %d", self.recPartition.array.count);
#endif
}

-(void)newLevel:(int)gameBPM {
	// NSLog(@"newLevel: %d", gameBPM);
    _currentMusicBPM = gameBPM;
    [self startPartitionWithBPM:_currentMusicBPM];
}

-(void)startPartitionWithBPM:(int)bpm
{
    // chargement de partition
	dispatch_sync(gcdQueue, ^{
    for (WHItem *item in self.activeItems) {
        [self removeChild:item cleanup:YES];
    }

    [self.activeItems removeAllObjects];
    });
	
    self.partition = [WHPartition new];
    [self.partition loadTrackWithBPM:bpm];
    // NSLog(@"#### partition chargée : %@",self.partition.array);
    _elapsedTime = 0.0;
}

-(float)adjustedDuration {
    return MAX_DURATION-_currentMusicBPM*1.15f;
}

-(void)initRecording {
    self.dateInit = [NSDate new];
    self.recPartition = [WHPartition new];
    self.recPartition.array = [NSMutableArray new];
}

-(void)itemTapped:(WHItem *)item {
    NSLog(@"HIT! Appliquer effet %d",[item effect]);
    BOOL itemSent = NO;
    
    if (_lastActionSuccess) {
        _jaugeSucces++;
    } else {
        _jaugeSucces = 1;
        _jaugeEchecs = 0;
        _lastActionSuccess = YES;
    }
    
    int jaugeStatut=0;
    if (_jaugeSucces >= 0 && _jaugeSucces < 3) {
        jaugeStatut = 1;
    } else if (_jaugeSucces < 6) {
        jaugeStatut = 2;
    }else {
        if (_shouldSendDrugToOpponent && item.type != ItemTypeNormal) {
            [self.gameScene sendDrug:item.type];
            itemSent = YES;
            jaugeStatut = 0;
            _jaugeSucces = 0;
            _shouldSendDrugToOpponent = NO;
        } else {
            jaugeStatut = 3;
            _shouldSendDrugToOpponent = YES;
        }
    }
    
    [self.gameScene updateJaugeWith:jaugeStatut];
    
	[self.gameScene mange:item withSent:itemSent];
    
    [self.activeItems removeObject:item];
    [self removeChild:item cleanup:YES];
    if (item.specialPeer != nil) {
        [self.activeItems removeObject:item.specialPeer];
        [self removeChild:item.specialPeer cleanup:YES];
    }
}



-(void)itemMissed:(BOOL)bigMiss {
    NSLog(@"%@ miss",bigMiss?@"Gros":@"Petit");
    if (!_lastActionSuccess) {
        _jaugeEchecs ++;
        _jaugeSucces = 0;
    } else {
        _jaugeEchecs = 0;
        _jaugeSucces = 0;
        _lastActionSuccess = NO;
    }
    
    [self.gameScene updateJaugeWith:0];
    
    int penalty = bigMiss?2:1;
	int time = [self.gameScene getTime];

	penalty = ((time/60)+1) * penalty;
    if ([self.gameScene getGameBPM] < BPM_MEDIAN) {
        penalty = -penalty;
    }
    [self.gameScene incrementBPM:penalty];
}

@end
