// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** use this contract to generate a series of (peudo-)random numbers given the range 
    Note: number generated will be replaced by the new number
*/

contract GenRand {
    uint256 private seed = 0;
    uint256[] values = [1,2,3,4,5,6,7,8,9,10]; 
    uint256 len = values.length;

    function nextRand(address from, uint newnum) internal returns (uint256){
        uint256 index = _random(from) % len;
        uint ret = values[index];
        values[index] = newnum;
        return ret;
    }

    function _random(address from) internal returns (uint256) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), from, seed)));
        seed = randomNumber;
        return randomNumber;
    }


}
