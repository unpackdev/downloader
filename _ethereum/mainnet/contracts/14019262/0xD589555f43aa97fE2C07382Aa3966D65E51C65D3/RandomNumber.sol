// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";
 
contract RandomNumber is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult = 10000;
    
    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
   function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = (randomness % 10000) + 1;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}