//Made by Pugnator.
contract FlipTest {
    bool paused;

    function pugnator69pause(bool _state) external {
        paused = _state;
    }

    function pugnator69(uint32 bot_type) external{
      require(!paused);
    }
}