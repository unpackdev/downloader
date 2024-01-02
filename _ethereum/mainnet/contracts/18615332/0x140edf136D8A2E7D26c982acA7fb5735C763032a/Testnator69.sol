contract Testnator69 {
    bool paused;

    function Go(bool _state) external {
        paused = _state;
    }

    function Mintpass(uint32 bot_type) external{
      require(!paused);
    }
}