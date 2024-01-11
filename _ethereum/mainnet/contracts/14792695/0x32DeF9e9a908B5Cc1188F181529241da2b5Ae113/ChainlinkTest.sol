// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AccessControl.sol";
import "./VRFConsumerBase.sol";


contract ChainlinkTest is AccessControl, VRFConsumerBase {

    // VRF
    bytes32 private vrfKeyHash;
    uint256 private vrfFee;

    uint256 public trueRandomness;

    constructor(address vrfCoordinatorAddress, address linkTokenAddress, bytes32 _vrfKeyHash, uint256 _vrfFee)
        VRFConsumerBase(vrfCoordinatorAddress, linkTokenAddress)
    {
        vrfKeyHash = _vrfKeyHash;
        vrfFee = _vrfFee;
    }


    //// RANDOMIZATION

    // Chainlink VRF handler
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        trueRandomness = randomness;
    }

    //// ADMIN SETUP FUNCTIONS

    function loadInitialRandomness() external onlyRole(ADMIN_ROLE) {
        requestRandomness(vrfKeyHash, vrfFee);
    }
}