// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

contract RandomOnce is VRFConsumerBase, Ownable {

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    uint256 public randomOffset;
    bytes32 public chainlinkRequestId;

    event RequestedRandomness(bytes32 requestId);
    event RequestedFulfilled(uint256 randomness);

    constructor(address _vrfCoordinator,
                address _link,
                bytes32 _keyHash,
                uint _fee)
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        )
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() external onlyOwner {
        // Contract can generate random number only once!
        require(randomResult == 0, 'Random number already generated');

        chainlinkRequestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(chainlinkRequestId);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        randomResult = randomness;
        // Pick last 5 digits as offset
        randomOffset = randomness % (10 * 10000);

        emit RequestedFulfilled(randomness);
    }

    function withdrawLink() external onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }
}