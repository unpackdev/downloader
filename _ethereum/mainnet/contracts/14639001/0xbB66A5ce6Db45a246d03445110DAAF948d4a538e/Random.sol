// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Random
/// @author Iwan <iwan@isotop.top>
/// @notice interface based on python random.randrange
library Random {

    function randrange(uint256 max, uint256 seed) view internal returns (uint256){
        if(max<=1){
            return 0;
        }
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % max;
    }

    function randrange(uint256 min, uint256 max, uint256 seed) view internal returns(uint256){
        if(min> max){
            revert("Min > Max");
        }
        return min+ randrange(max-min, seed);
    }
}