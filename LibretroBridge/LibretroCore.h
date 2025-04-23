//
//  LibretroCore.h
//  SwiftRetro
//
//  Created by Matt Hammond on 4/8/25.
//

#import "CoreOption.h"
#import "libretro.h"
#import <Foundation/Foundation.h>

#ifndef LibretroCore_h
#define LibretroCore_h

NS_ASSUME_NONNULL_BEGIN

// Forward declare delegate protocol
@protocol LibretroCoreDelegate;

@interface LibretroCore : NSObject

@property(nonatomic, weak) id<LibretroCoreDelegate> delegate;
// Core options
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, CoreOption *> *coreOptions;
@property(nonatomic, assign) BOOL optionsUpdated;
@property(nonatomic, readonly) BOOL supportNoGame;
@property(nonatomic, readonly) BOOL gameLoaded;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithCorePath:(NSString *)corePath
    NS_DESIGNATED_INITIALIZER;

- (BOOL)load;
- (void)unload;
- (BOOL)loadGame;
- (BOOL)loadGame:(NSString *)gamePath;
- (void)unloadGame;
- (uint64_t)getTargetFrameMicroseconds;

// Main loop function
- (void)runFrame;

@end

// Delegate protocol for callbacks to Swift/Frontend UI
@protocol LibretroCoreDelegate <NSObject>
- (void)renderVideoFrame:(const void *)data
                   width:(unsigned)width
                  height:(unsigned)height
                   pitch:(size_t)pitch
                  format:(enum retro_pixel_format)format;
- (void)playAudioSamples:(const int16_t *)data frames:(size_t)frames;
- (int16_t)getInputState:(unsigned)port
                  device:(unsigned)device
                   index:(unsigned)index
                      id:(unsigned)id;
- (void)pollInput;
// ... other delegate methods for environment calls, logging etc.
@end

NS_ASSUME_NONNULL_END

#endif /* LibretroCore_h */
