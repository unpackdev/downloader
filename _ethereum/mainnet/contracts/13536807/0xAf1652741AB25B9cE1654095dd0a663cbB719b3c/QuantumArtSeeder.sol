// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IQuantumArtSeeder.sol";
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract QuantumArtSeeder is IQuantumArtSeeder, Ownable, VRFConsumerBase {
    
    mapping (uint256 => uint256) private _dropIdToSeed;
    
    bytes32 immutable private _keyHash;
    uint256 immutable private _fee;
    
    uint256 private _seederDropIdCounter;
    
    constructor(
        address link,
        address vrfCoordinator,
        bytes32 keyHash,
        uint256 fee) 
        VRFConsumerBase(
            vrfCoordinator,
            link
        )
    {
        _keyHash = keyHash;
        _fee = fee;
    }

    function setSeed(uint256 dropId, uint256 seed) onlyOwner public {
        _dropIdToSeed[dropId] = seed;
    }

    //use if we want to skip some drops for example
    function setCounter(uint256 counter) onlyOwner public {
        _seederDropIdCounter = counter;
    }

    function dropIdToSeed(uint256 dropId) public view override returns (uint256) {
        return _dropIdToSeed[dropId];
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() onlyOwner public returns (bytes32 requestId) {
        require(LINK.transferFrom(msg.sender, address(this), _fee), "Cannot transfer fee");
        require(LINK.balanceOf(address(this)) >= _fee, "Not enough LINK");
        return requestRandomness(_keyHash, _fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _dropIdToSeed[_seederDropIdCounter++] = randomness;
    }

}