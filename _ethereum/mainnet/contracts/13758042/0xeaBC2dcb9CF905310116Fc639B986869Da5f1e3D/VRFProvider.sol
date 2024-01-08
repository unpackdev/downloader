// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./VRFConsumerBase.sol";

import "./IRandomnessConsumer.sol";
import "./IRandomnessProvider.sol";

contract VRFProvider is IRandomnessProvider, Ownable, VRFConsumerBase {
    // keyHash for VRF
    bytes32 internal keyHash;
    // link fee for VRF
    uint256 internal fee;

    // mapping to random result for requestIds
    mapping(bytes32 => uint256) public requestIdKeys;

    IRandomnessConsumer public randomnessConsumer;

    constructor(
        address _linkToken,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint256 _fee,
        IRandomnessConsumer _consumer
    ) VRFConsumerBase(_vrfCoordinator, _linkToken) {
        keyHash = _keyHash;
        fee = _fee;

        randomnessConsumer = _consumer;
    }

    /**
     * Do some processing
     */
    function newRandomnessRequest() external override returns (bytes32) {
        require(
            msg.sender == address(randomnessConsumer),
            'Only consumer is allowed'
        );
        if (LINK.balanceOf(address(this)) >= fee) {
            return VRFConsumerBase.requestRandomness(keyHash, fee);
        }

        return '';
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomnessConsumer.setRandomnessResult(requestId, randomness);
    }

    /**
     * Update link fee needed to request randomness
     */
    function updateFee(uint256 _fee) external override {
        require(
            msg.sender == address(randomnessConsumer),
            'Only consumer is allowed'
        );
        fee = _fee;
    }

    /**
     * allows owner to rescue LINK tokens
     */
    function rescueLINK(address to, uint256 amount) external override {
        require(
            msg.sender == address(randomnessConsumer),
            'Only consumer is allowed'
        );
        LINK.transfer(to, amount);
    }
}
