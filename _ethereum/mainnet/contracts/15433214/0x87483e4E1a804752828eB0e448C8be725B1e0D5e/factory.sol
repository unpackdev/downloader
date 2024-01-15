//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
/// @title time contract
contract factory {
/// @notice get blocktime
/// @return block.timestamp
    function getTime()
    external view returns(uint256){
        return block.timestamp;
    }
}