pragma solidity ^0.4.24;

contract VotingPausable {
    bool public paused;
    address private pauser;

    constructor() public {
        pauser = msg.sender;
    }

    modifier whenNotPaused() {
        require(!paused, "paused");
        _;
    }

    function setPaused(bool _paused) external {
        require(msg.sender == pauser, "!pauser");
        paused = _paused;
    }

    function transferOwnership(address newPauser) public {
        require(msg.sender == pauser, "!pauser");
        pauser = newPauser;
    }
}
