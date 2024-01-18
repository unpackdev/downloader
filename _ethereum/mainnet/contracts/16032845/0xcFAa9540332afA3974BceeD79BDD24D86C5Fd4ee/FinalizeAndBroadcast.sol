pragma solidity 0.8.17;

import "./PendleVotingControllerUpg.sol";

contract FinalizeAndBroadcast {
    PendleVotingControllerUpg immutable votingController;

    constructor(address _votingController) {
        votingController = PendleVotingControllerUpg(_votingController);
    }

    function run() external {
        votingController.finalizeEpoch();
        votingController.broadcastResults(uint64(block.chainid));
    }
}
