//SPDX-License-Identifier: None
pragma solidity ^0.8.10;
import "./Ownable.sol";
import "./VRFConsumerBase.sol";

// Decentralized, fair (assuming no single authority controls the largest ethereum holders)
contract Randomizer is Ownable, VRFConsumerBase{

    bytes32 public keyHash;
    uint256 public fee;
    uint256[] public randomResult;

    mapping( address => bool ) public isRandomizerAddress;

    constructor() Ownable() VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA){ // vrf coordinator, link token address
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445; 
        fee = 2 * 10 ** 18; //2 LINK
    }

    /* Submits request to Chainlink VRF Coordinator to provide verifiably random number*/
    function randomWinner() internal returns(bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK in contract");
        return requestRandomness(keyHash, fee);
    }

    /* Done so that the first index of randomResult will be picked even if randomWinner is called multiple times due to any unprecedented failure in getting the random number */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult.push(randomness);
    }
}