// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

import "./ICAMP.sol";
import "./IGovernance.sol";

contract RandomNumberConsumer is VRFConsumerBase, Ownable {
    bytes32 internal keyHash;
    uint256 internal fee;

    mapping (bytes32 => uint) public requestIds;

    IGovernance public governance;

    event NumberRequested (
        uint winnerId,
        bytes32 requestId
    );

    event NumberReceived (
        bytes32 requestId,
        uint256 randomness
    );

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint _fee, address _governance)
        VRFConsumerBase(
            _vrfCoordinator,
            _link
        ) public
    {
        keyHash = _keyHash;
        fee = _fee;
        governance = IGovernance(_governance);
    }

    function getRandomNumber(uint winnerId) external {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK.");
        address giveawayAddress = governance.giveaway();
        require(msg.sender == giveawayAddress, "Invalid sender getting random.");

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIds[requestId] = winnerId;
        emit NumberRequested(winnerId, requestId);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address giveawayAddress = governance.giveaway();
        ICAMP camp = ICAMP(giveawayAddress);
        camp.processPickedWinner(requestIds[requestId], randomness);
        emit NumberReceived(requestId, randomness);
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}
