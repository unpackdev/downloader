// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFConsumerBase.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */
 
contract Random is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    mapping(address=>bool) allowedAddress;
    address adminAddress;
    
    /**
     * Constructor inherits VRFConsumerBase
     * // reference https://docs.chain.link/docs/vrf-contracts/
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
        adminAddress = msg.sender; // 0x9b6D7b08460e3c2a1f4DFF3B2881a854b4f3b859;
    }
    
       
    /** 
     * Requests randomness 
     */
    function getRandomNumber() checkAllowed(msg.sender) external returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness ;
    }

    function getRandomVal() checkAllowed(msg.sender) external view returns (uint256)
    {
        return(randomResult);
    }

    function emergencyWithdraw(address backup) public {
        require(msg.sender == adminAddress);
        LINK.transfer(backup,LINK.balanceOf(address(this)));
    }
    function allowAddress(address allow) public {
        require(msg.sender == adminAddress);
        allowedAddress[allow] = true;
    }
    function removeAddress(address remove) public {
        require(msg.sender == adminAddress);
        allowedAddress[remove] = false;
    }
 
    modifier checkAllowed(address add) {
        require(allowedAddress[add]==true, "not authorized to call this function");
        _;
    }
}
