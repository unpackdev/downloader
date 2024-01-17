// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Altar {
    address enigmaticBox;
    mapping(address => mapping ( uint256 => uint256)) public boxesOnAltar; //address => boxType => amount
    
    function batchStartRitual(address to, uint256[] calldata boxTypes) external {
        if(msg.sender != enigmaticBox) revert();
        for (uint256 i; i < boxTypes.length; ++i) {
            boxesOnAltar[to][boxTypes[i]]++;
        }

    }
    function startRitual(address to, uint256 boxType) external {
        if(msg.sender != enigmaticBox) revert();
        boxesOnAltar[to][boxType] = 1;
    }

    constructor(address boxContract) {//, address inflator
        enigmaticBox = boxContract; //0xBE82b9533Ddf0ACaDdcAa6aF38830ff4B919482C
        //inflateContract = IInflator(inflator);
        /*for (uint256 i; i < 5000; ++i) {
            (bool nesting,,) = claimContract.nestingPeriod(i);
            //if(!nesting) notClaimable.set(i);
            
        }*/
    }



}