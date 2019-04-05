//
//  ViewController.m
//  simpleMazeGame
//
//  Created by Admin on 04.04.19.
//  Copyright © 2019 bataevvlad. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
#import <QuartzCore/QuartzCore.h>

#define kUpdateInterval (1.0f / 60.0f);

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *pacman;
@property (strong, nonatomic) IBOutlet UIImageView *ghost1;
@property (strong, nonatomic) IBOutlet UIImageView *ghost2;
@property (strong, nonatomic) IBOutlet UIImageView *ghost3;
@property (strong, nonatomic) IBOutlet UIImageView *exit;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *wall;

@property (assign, nonatomic) CGPoint currentPoint;
@property (assign, nonatomic) CGPoint previousPoint;
@property (assign, nonatomic) CGFloat pacmanXVelocity;
@property (assign, nonatomic) CGFloat pacmanYVelocity;
@property (assign, nonatomic) CGFloat angle;
@property (assign, nonatomic) CMAcceleration acceleration;
@property (strong, nonatomic) CMMotionManager *motionManager;
@property (strong, nonatomic) NSOperationQueue *queue;
@property (strong, nonatomic) NSDate *lastUpdateTime;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGPoint origin1 = self.ghost1.center;
    CGPoint target1 = CGPointMake(self.ghost1.center.x, self.ghost1.center.y-300);
    
    CABasicAnimation *bounce1 = [CABasicAnimation animationWithKeyPath:@"position.y"];
    bounce1.fromValue = [NSNumber numberWithInt:origin1.y];
    bounce1.toValue = [NSNumber numberWithInt:target1.y];
    bounce1.duration = 2;
    bounce1.autoreverses = YES;
    bounce1.repeatCount = HUGE_VALF;
    
    [self.ghost1.layer addAnimation:bounce1 forKey:@"position"];
    
    CGPoint origin2 = self.ghost2.center;
    CGPoint target2 = CGPointMake(self.ghost2.center.x, self.ghost2.center.y-210);
    CABasicAnimation *bounce2 = [CABasicAnimation animationWithKeyPath:@"position.y"];
    bounce2.fromValue = [NSNumber numberWithInt:origin2.y];
    bounce2.toValue = [NSNumber numberWithInt:target2.y];
    bounce2.duration = 2;
    bounce2.repeatCount = HUGE_VALF;
    bounce2.autoreverses = YES;
    [self.ghost2.layer addAnimation:bounce2 forKey:@"position"];
    
    CGPoint origin3 = self.ghost3.center;
    CGPoint target3 = CGPointMake(self.ghost3.center.x, self.ghost3.center.y+384);
    CABasicAnimation *bounce3 = [CABasicAnimation animationWithKeyPath:@"position.y"];
    bounce3.fromValue = [NSNumber numberWithInt:origin3.y];
    bounce3.toValue = [NSNumber numberWithInt:target3.y];
    bounce3.duration = 2;
    bounce3.repeatCount = HUGE_VALF;
    bounce3.autoreverses = YES;
    [self.ghost3.layer addAnimation:bounce3 forKey:@"position"];
    
    //Pacman movement;
    self.lastUpdateTime = [[NSDate alloc] init];
    
    self.currentPoint  = CGPointMake(0, 144);
    self.motionManager = [[CMMotionManager alloc] init];
    self.queue         = [[NSOperationQueue alloc] init];
    
    self.motionManager.accelerometerUpdateInterval = kUpdateInterval;
    
    [self.motionManager startAccelerometerUpdatesToQueue:self.queue withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
        [(id) self setAcceleration:accelerometerData.acceleration];
        [self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
    }];
}

#pragma mark -Update

- (void) update {
    NSTimeInterval secondSinceLastDraw = -([self.lastUpdateTime timeIntervalSinceNow]);
    self.pacmanYVelocity = self.pacmanYVelocity - (self.acceleration.x * secondSinceLastDraw);
    self.pacmanXVelocity = self.pacmanXVelocity - (self.acceleration.y * secondSinceLastDraw);

    CGFloat xDelta = secondSinceLastDraw * self.pacmanYVelocity * 500;
    CGFloat yDelta = secondSinceLastDraw * self.pacmanYVelocity * 500;
    
    self.currentPoint = CGPointMake(self.currentPoint.x + xDelta, self.currentPoint.y + yDelta);
    
    [self movePacman];
    
    self.lastUpdateTime = [NSDate date];
}

#pragma mark -Pacman Movement

- (void)movePacman {
    
    [self collisionWithExit];
    [self collisionWithGhosts];
    [self collisionWithWalls];
    [self collisionWithBoundaries];
    
    self.previousPoint = self.currentPoint;
    
    CGRect frame = self.pacman.frame;
    frame.origin.x = self.currentPoint.x;
    frame.origin.y = self.currentPoint.y;
    
    self.pacman.frame = frame;
    
    //Rotate sprite;
    
    CGFloat newAngle = (self.pacmanXVelocity + self.pacmanYVelocity) * M_PI * 4;
    self.angle += newAngle * kUpdateInterval;
    
    CABasicAnimation *rotate;
    rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.fromValue = [NSNumber numberWithFloat:0];
    rotate.toValue = [NSNumber numberWithFloat:self.angle];
    rotate.duration = kUpdateInterval;
    rotate.repeatCount = 1;
    rotate.removedOnCompletion = NO;
    rotate.fillMode = kCAFillModeForwards;
    [self.pacman.layer addAnimation:rotate forKey:@"10"];
    
}

#pragma mark -Collisions
//Need to check if the frame of pacman is inside the screen.
- (void)collisionWithBoundaries {
    
    if (self.currentPoint.x < 0) {
        _currentPoint.x = 0;
        self.pacmanYVelocity = -(self.pacmanXVelocity / 2.0);
    }
    if (self.currentPoint.y < 0) {
        _currentPoint.y = 0;
        self.pacmanXVelocity = -(self.pacmanYVelocity / 2.0);
    }
    
    if (self.currentPoint.x > self.view.bounds.size.width - self.pacman.image.size.width) {
        _currentPoint.x = self.view.bounds.size.width - self.pacman.image.size.width;
        self.pacmanXVelocity = -(self.pacmanXVelocity / 2.0);
    }
    
    if (self.currentPoint.y > self.view.bounds.size.height - self.pacman.image.size.height) {
        _currentPoint.y = self.view.bounds.size.height - self.pacman.image.size.height;
        self.pacmanYVelocity = -(self.pacmanYVelocity / 2.0);
        
    }
}
//Collision with exit;
//Need test;
- (void)collisionWithExit {
    if (CGRectIntersectsRect(self.pacman.frame, self.exit.frame)) {
        [self.motionManager stopAccelerometerUpdates];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Congrats!"
                                                                       message:@"You won the game!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* yesButton = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                    }];
        
        
        [alert addAction:yesButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

//Collision with ghosts;

- (void)collisionWithGhosts {
    
    CALayer *ghostLayer1 = [self.ghost1.layer presentationLayer];
    CALayer *ghostLayer2 = [self.ghost2.layer presentationLayer];
    CALayer *ghostLayer3 = [self.ghost3.layer presentationLayer];

    if (CGRectIntersectsRect(self.pacman.frame, ghostLayer1.frame) ||
        CGRectIntersectsRect(self.pacman.frame, ghostLayer2.frame) ||
        CGRectIntersectsRect(self.pacman.frame, ghostLayer3.frame)) {
        
        self.currentPoint = CGPointMake(0, 144);
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Oops!"
                                                                       message:@"You lose!"
                                                        preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* button = [UIAlertAction
                                    actionWithTitle:@"Ok"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                    }];
        
        
        [alert addAction:button];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

// Collision with game walls;
- (void) collisionWithWalls {
    
    CGRect frame = self.pacman.frame;
    frame.origin.x = self.currentPoint.x;
    frame.origin.y = self.currentPoint.y;
    
    for (UIImageView *image in self.wall) {
        
        if (CGRectIntersectsRect(frame, image.frame)) {
            
            //Collision angle;
            CGPoint pacmanCenter = CGPointMake(frame.origin.x + (frame.size.width / 2),
                                               frame.origin.y + (frame.size.height / 2));
            CGPoint imageCenter = CGPointMake(image.frame.origin.x + (image.frame.size.width /2),
                                              image.frame.origin.y + (image.frame.size.height / 2));
            CGFloat angleX = pacmanCenter.x - imageCenter.x;
            CGFloat angleY = pacmanCenter.y - imageCenter.y;
            
            if (fabs(angleX) > fabs(angleY)) {
                _currentPoint.x = self.previousPoint.x;
                self.pacmanXVelocity = -(self.pacmanXVelocity / 2.0);
            } else {
                _currentPoint.y = self.previousPoint.y;
                self.pacmanYVelocity = -(self.pacmanXVelocity / 2.0);
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
