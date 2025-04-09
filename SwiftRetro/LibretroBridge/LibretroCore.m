//
//  LibretroCore.m
//  SwiftRetro
//
//  Created by Matt Hammond on 4/8/25.
//

#import "LibretroCore.h"
#import "libretro.h"
#import <dlfcn.h> // For dlopen, dlsym, dlclose
#import <os/log.h>

static os_log_t loggerInstance;
static os_log_t logger(void) {
    if (!loggerInstance) {
        loggerInstance = os_log_create("com.mbh.SwiftRetro", "LibretroCore");
    }
    return loggerInstance;
}

// MARK: LibretroCore Declarations

@implementation LibretroCore {
    // For some reason "==" doesn't work when comparing "currently_loaded_core"
    // and "self", so we have to keep track of whether this core is active.
    bool isActive;

    bool supportNoGame;

    // Handle for the dynamic library
    void *coreHandle;

    // Callback setters
    void (*retro_set_environment)(retro_environment_t cb);
    void (*retro_set_video_refresh)(retro_video_refresh_t cb);
    void (*retro_set_audio_sample)(retro_audio_sample_t cb);
    void (*retro_set_audio_sample_batch)(retro_audio_sample_batch_t cb);
    void (*retro_set_input_poll)(retro_input_poll_t cb);
    void (*retro_set_input_state)(retro_input_state_t cb);

    // init/deinit
    void (*retro_init)(void);
    void (*retro_deinit)(void);

    // info getters
    unsigned (*retro_api_version)(void);
    void (*retro_get_system_info)(struct retro_system_info *info);
    void (*retro_get_system_av_info)(struct retro_system_av_info *info);

    // controller
    void (*retro_set_controller_port_device)(unsigned port, unsigned device);

    // reset/run
    void (*retro_reset)(void);
    void (*retro_run)(void);

    // serialization
    size_t (*retro_serialize_size)(void);
    bool (*retro_serialize)(void *data, size_t len);
    bool (*retro_unserialize)(void *data, size_t len);

    // cheats
    void (*retro_cheat_reset)(void);
    void (*retro_cheat_set)(unsigned index, bool enabled, const char *code);

    // game loading
    bool (*retro_load_game)(const struct retro_game_info *game);
    bool (*retro_load_game_special)(unsigned game_type,
                                    const struct retro_game_info *info,
                                    size_t num_info);
    void (*retro_unload_game)(void);
    unsigned (*retro_get_region)(void);

    // memory
    void *(*retro_get_memory_data)(unsigned id);
    size_t (*retro_get_memory_size)(unsigned id);
}

// MARK: Static Libretro C Callbacks

static __weak LibretroCore *current_loaded_core = nil;

static bool environment_callback(unsigned cmd, void *data) {
    os_log_debug(logger(), "[Environment] Received command %d", cmd);
    LibretroCore *core = current_loaded_core;
    if (!core) {
        os_log_fault(logger(), "[Environment] No loaded core.");
        return false;
    }
    switch (cmd) {
    case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME:
        core->supportNoGame = true;
        return true;
    }
    os_log_error(logger(), "[Environment] Unknown command: %d", cmd);
    return false;
}

static void video_refresh_callback(const void *data, unsigned width,
                                   unsigned height, size_t pitch) {}

static void audio_sample_callback(int16_t left, int16_t right) {}

static size_t audio_sample_batch_callback(const int16_t *data, size_t frames) {
    return 0;
}

static void input_poll_callback(void) {}

static int16_t input_state_callback(unsigned port, unsigned device,
                                    unsigned index, unsigned id) {
    return 0;
}

// MARK: LibretroCore Implementation

- (nullable instancetype)initWithCorePath:(NSString *)corePath {
    os_log_info(logger(), "[Core Alloc] Attempting to open core at path %@",
                corePath);
    coreHandle = dlopen(corePath.UTF8String, RTLD_LAZY);
    if (!coreHandle) {
        os_log_fault(logger(), "[Core Alloc] Failed to open core: %s",
                     dlerror());
        return nil;
    }

    // Callback setters
    retro_set_environment = dlsym(coreHandle, "retro_set_environment");
    retro_set_video_refresh = dlsym(coreHandle, "retro_set_video_refresh");
    retro_set_audio_sample = dlsym(coreHandle, "retro_set_audio_sample");
    retro_set_audio_sample_batch =
        dlsym(coreHandle, "retro_set_audio_sample_batch");
    retro_set_input_poll = dlsym(coreHandle, "retro_set_input_poll");
    retro_set_input_state = dlsym(coreHandle, "retro_set_input_state");

    // init/deinit
    retro_init = dlsym(coreHandle, "retro_init");
    retro_deinit = dlsym(coreHandle, "retro_deinit");

    // info getters
    retro_api_version = dlsym(coreHandle, "retro_api_version");
    retro_get_system_info = dlsym(coreHandle, "retro_get_system_info");
    retro_get_system_av_info = dlsym(coreHandle, "retro_get_system_av_info");

    // controller
    retro_set_controller_port_device =
        dlsym(coreHandle, "retro_set_controller_port_device");

    // reset/run
    retro_reset = dlsym(coreHandle, "retro_reset");
    retro_run = dlsym(coreHandle, "retro_run");

    // serialization
    retro_serialize_size = dlsym(coreHandle, "retro_serialize_size");
    retro_serialize = dlsym(coreHandle, "retro_serialize");
    retro_unserialize = dlsym(coreHandle, "retro_unserialize");

    // cheats
    retro_cheat_reset = dlsym(coreHandle, "retro_cheat_reset");
    retro_cheat_set = dlsym(coreHandle, "retro_cheat_set");

    // game loading
    retro_load_game = dlsym(coreHandle, "retro_load_game");
    retro_load_game_special = dlsym(coreHandle, "retro_load_game_special");
    retro_unload_game = dlsym(coreHandle, "retro_unload_game");
    retro_get_region = dlsym(coreHandle, "retro_get_region");

    // memory
    retro_get_memory_data = dlsym(coreHandle, "retro_get_memory_data");
    retro_get_memory_size = dlsym(coreHandle, "retro_get_memory_size");

    // TODO: Check for all functions somehow
    if (!retro_init || !retro_load_game || !retro_run) {
        os_log_fault(logger(),
                     "[Core Alloc] Missing required retro API symbols.");
        return nil;
    }
    return self;
}

- (void)dealloc {
    if (isActive) {
        [self unload];
    }
    if (coreHandle) {
        dlclose(coreHandle);
    }
    os_log_debug(logger(), "[Core Dealloc] Finished deallocating core.");
}

- (BOOL)load {
    if (current_loaded_core != nil) {
        os_log_error(logger(),
                     "[LoadCore] Another core instance is already active.");
        return NO;
    }

    if (retro_api_version() != RETRO_API_VERSION) {
        os_log_error(
            logger(),
            "[LoadCore] Unsupported retro API version. Required: %d; Found: %d",
            RETRO_API_VERSION, retro_api_version());
        return NO;
    }

    struct retro_system_info systemInfo = {0};
    retro_get_system_info(&systemInfo);
    os_log_info(logger(), "[LoadCore] Initializing core: %s",
                systemInfo.library_name);

    // TODO: initialize state used by static callbacks.

    // Make sure the static callbacks can reference this instance before
    // installing them.
    current_loaded_core = self;
    isActive = true;

    retro_set_environment(environment_callback);
    retro_set_video_refresh(video_refresh_callback);
    retro_set_audio_sample(audio_sample_callback);
    retro_set_audio_sample_batch(audio_sample_batch_callback);
    retro_set_input_poll(input_poll_callback);
    retro_set_input_state(input_state_callback);

    retro_init();

    os_log_info(logger(), "[LoadCore] Successfully loaded core: %s",
                systemInfo.library_name);
    return YES;
}

- (void)unload {
    if (!isActive) {
        os_log_error(
            logger(),
            "[UnloadCore] Attempted to unload an already unloaded core.");
        return;
    }
    struct retro_system_info systemInfo = {0};
    retro_get_system_info(&systemInfo);

    if (retro_deinit) {
        retro_deinit();
    }

    isActive = false;
    current_loaded_core = nil;
    os_log_info(logger(), "[UnloadCore] Successfully unloaded core: %s",
                systemInfo.library_name);
}

- (void)runFrame {
    if (!isActive) {
        os_log_error(logger(), "[RunFrame] Attempted to run an unloaded core.");
        return;
    }
    if (retro_run) {
        retro_run();
    }
}

@end
