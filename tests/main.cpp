#include <iostream>
#include <filesystem>
#include <unistd.h>
#include "AudioVLC.h"
using namespace std;

static constexpr int TIMEOUT_MS = 3 * 1000;
static constexpr int TICK_MS    = 100;

enum class Test {
    Wait,
    Skip,
    Fail,
    Pass,
};

/****************************
 * Player
 ****************************/
class Player
{
public:
    ~Player();

    void run(const string &url);

    bool debug() const { return mDebug; }
    void setDebug(bool value) { mDebug = value; }

    Test connectionTest() const { return mConnectionTest; }
    Test metadataTest() const { return mMetadataTest; }

    void skipConnectionTest() { mConnectionTest = Test::Skip; }
    void skipMetadataTest() { mMetadataTest = Test::Skip; }

private:
    string                 mUrl;
    libvlc_instance_t     *mVlc            = nullptr;
    libvlc_media_player_t *mPlayer         = nullptr;
    bool                   mHasErros       = false;
    bool                   mDebug          = false;
    Test                   mConnectionTest = Test::Wait;
    Test                   mMetadataTest   = Test::Wait;

    bool isFinished();
    void testVolume();
    void testMute();

    static void logCallback(void *data, int level, const libvlc_log_t *ctx, const char *fmt, va_list args);
    static void vlcEvent(const libvlc_event_t *event, void *userdata);
};

/****************************
 *
 ****************************/
Player::~Player()
{
    if (mPlayer) {
        libvlc_media_player_release(mPlayer);
    }

    if (mVlc) {
        libvlc_release(mVlc);
    }
}

/****************************
 *
 ****************************/
void Player::run(const string &url)
{
    mHasErros = false;

    const char *vlc_args[] = {};
    mVlc                   = libvlc_new(sizeof(vlc_args) / sizeof(vlc_args[0]), vlc_args);
    if (!mVlc) {
        throw string("VLC instance load error!");
    }
    libvlc_log_set(mVlc, logCallback, this);

    libvlc_media_t *media = libvlc_media_new_location(mVlc, url.c_str());
    if (!media) {
        throw string("VLC media load error!");
    }

    // mPlayer = libvlc_media_player_new_from_media(media);
    mPlayer = libvlc_media_player_new(mVlc);
    if (!mPlayer) {
        throw string("VLC player load error!");
    }

    libvlc_media_player_set_media(mPlayer, media);
    libvlc_media_release(media);

    {
        vector<libvlc_event_e> events = {
            libvlc_MediaPlayerPlaying,
            libvlc_MediaPlayerPaused,
            libvlc_MediaPlayerStopped,
            libvlc_MediaPlayerEncounteredError,
            libvlc_VlmMediaInstanceStatusError,
        };

        libvlc_event_manager_t *playerEvents = libvlc_media_player_event_manager(mPlayer);
        for (auto ev : events) {
            if (libvlc_event_attach(playerEvents, ev, vlcEvent, this) != 0) {
                throw string("VLC event_attach error!");
            }
        }
    }

    {
        vector<libvlc_event_e> events = {
            libvlc_MediaMetaChanged,
        };

        libvlc_event_manager_t *mediaEvents = libvlc_media_event_manager(media);
        for (auto ev : events) {
            if (libvlc_event_attach(mediaEvents, ev, vlcEvent, this) != 0) {
                throw string("VLC event_attach error!");
            }
        }
    }

    testVolume();
    testMute();

    libvlc_audio_set_volume(mPlayer, 0);
    if (libvlc_media_player_play(mPlayer) != 0) {
        throw string("libvlc_media_player_play error: ") + libvlc_errmsg();
    }

    int timeout = TIMEOUT_MS;
    while (timeout > 0) {
        usleep(TICK_MS * 1000);
        timeout -= TICK_MS;
        if (isFinished()) {
            return;
        }
    }

    for (Test *t : { &mConnectionTest, &mMetadataTest }) {
        if (*t == Test::Wait) {
            *t = Test::Fail;
        }
    }
}

/****************************
 *
 ****************************/
bool Player::isFinished()
{
    // clang-format off
    return
        mConnectionTest != Test::Wait &&
        mMetadataTest   != Test::Wait;
    // clang-format on
}

/****************************
 *
 ****************************/
void Player::testVolume()
{
    const int volume_tests[] = { 0, 50, 100 };
    for (int volume : volume_tests) {
        if (libvlc_audio_set_volume(mPlayer, volume) != 0) {
            throw string("libvlc_audio_set_volume error for" + std::to_string(volume));
        }
    }
}

/****************************
 *
 ****************************/
void Player::testMute()
{
    const bool mute_tests[] = { true, false };
    for (auto mute : mute_tests) {
        libvlc_audio_set_mute(mPlayer, mute ? 1 : 0);
    }
}

/****************************
 *
 ****************************/
void Player::logCallback(void *data, int level, const libvlc_log_t *ctx, const char *fmt, va_list args)
{
    Player *player = static_cast<Player *>(data);

    string lvl;
    // clang-format off
    switch (level) {
        case LIBVLC_DEBUG:   lvl = "Debug";   break;
        case LIBVLC_NOTICE:  lvl = "Info";    break;
        case LIBVLC_WARNING: lvl = "Warning"; break;
        case LIBVLC_ERROR:   lvl = "Error";   break;
    }
    // clang-format off

    if (player->debug() == false && level < LIBVLC_NOTICE) {
        return;
    }

    if (level == LIBVLC_ERROR) {

        player->mHasErros = true;
    }

    fprintf(stderr, "    VLC LOG [%s]: ", lvl.c_str());
    vfprintf(stderr, fmt, args);
    fprintf(stderr, "\n");
}

/****************************
 *
 ****************************/
void Player::vlcEvent(const libvlc_event_t *event, void *data)
{
    Player *player = static_cast<Player*>(data);


    switch (event->type) {
        case libvlc_MediaPlayerPlaying:
            if ( player->mConnectionTest == Test::Wait) {
                player->mConnectionTest = player->mHasErros ? Test::Fail : Test::Pass;
            }
            break;

        case libvlc_MediaPlayerPaused:
            break;

        case libvlc_MediaPlayerStopped:
            break;

        case libvlc_MediaPlayerEncounteredError:
            if ( player->mConnectionTest == Test::Wait) {
                player->mConnectionTest = Test::Fail;
            }
            break;

        case libvlc_MediaMetaChanged: {
            if (player->mMetadataTest == Test::Wait) {
                libvlc_media_t *media = static_cast<libvlc_media_t *>(event->p_obj);
                if (libvlc_media_get_meta(media, libvlc_meta_NowPlaying)) {
                    player->mMetadataTest = Test::Pass;
                }
            }
            break;
        }
        default:
            break;
    }
}

/****************************
 *
 ****************************/
bool printTestStatus(const Test status, const string &testName, const string &url) {
    string prefix;
    // clang-format off
    switch (status) {
        case Test::Wait: cout << "WAIT"; break;
        case Test::Skip: cout << "SKIP"; break;
        case Test::Fail: cout << "FAIL"; break;
        case Test::Pass: cout << "PASS"; break;
    }
    // clang-format on

    cout << "    : " << testName << endl; // << " for " << url << endl;

    // clang-format off
    switch (status) {
        case Test::Wait: return false;
        case Test::Skip: return true;
        case Test::Fail: return false;
        case Test::Pass: return true;
    }
    // clang-format on
    return false;
}

/****************************
 *
 ****************************/
void printUsage(filesystem::path path)
{
    cerr << "Usage " << path.filename() << "[OPTION] URL" << endl;
    cerr << endl;
    cerr << "Options:" << endl;
    cerr << "  --debug                      Print VLC demug messages" << endl;
    cerr << "  --skip-metadata              Skip metadata test" << endl;
}

/****************************
 *
 ****************************/
int main(int argc, char *argv[])
{
    filesystem::path path(argv[0]);
    if (argc < 2) {
        printUsage(path);
        return 100;
    }

    Player player;

    string url;
    for (int i = 1; i < argc; ++i) {
        string arg(argv[i]);

        if (arg.rfind("-", 0) != 0) {
            url = arg;
            continue;
        }

        if (arg == "--debug") {
            player.setDebug(true);
            continue;
        }

        if (arg == "--skip-metadata") {
            player.skipMetadataTest();
            continue;
        }

        cerr << "unrecognized option '" << arg << "'" << endl;
        printUsage(path);
        return 101;
    }

    cout << "*********************************" << endl;
    cout << "Start testing of " << url << endl;

    filesystem::path frameWorkPath = path.parent_path().append(BUILD_RPATH);
    string           pluginsPath   = frameWorkPath.append("AudioVLC.framework/plugins");

    try {
        if (!filesystem::is_directory(filesystem::status(frameWorkPath))) {
            //  throw string("framework not found: " + frameWorkPath.string());
        }

        if (!filesystem::is_directory(filesystem::status(pluginsPath))) {
            //   throw string("plugins not found: " + pluginsPath);
        }

        setenv("VLC_PLUGIN_PATH", pluginsPath.c_str(), 1);

        player.run(url);

        bool ok = true;

        ok = printTestStatus(player.connectionTest(), "Connect ", url) && ok;
        ok = printTestStatus(player.metadataTest(), "Metadata", url) && ok;

        return ok ? 0 : 2;
    }
    catch (const string &err) {
        cout << "   Error: " << err;
        printTestStatus(Test::Fail, "Init    ", url);
        return 1;
    }
}
