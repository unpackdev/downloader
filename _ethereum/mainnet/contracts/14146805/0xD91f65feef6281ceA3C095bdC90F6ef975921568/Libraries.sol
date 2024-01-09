// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Uint256Array {
  uint256 constant MAX_INT = 2 ** 256 - 1;
  function indexOf(uint256[] storage values, uint256 value) internal view returns(uint256) {
    for(uint256 index = 0; index < values.length; index++){
      if(values[index] == value){
        return index;
      }
    }
    return MAX_INT;
  }
  function remove(uint256[] storage values, uint256 value) internal {
    uint index = indexOf(values, value);
    if(index < values.length){
      removeIndex(values, index);
    }
  }
  function removeIndex(uint256[] storage values, uint256 index) internal {
    if(index < values.length){
      
      uint i = index;
      while(i < values.length-1){
        values[i] = values[i+1];
        i++;
      }
      values.pop();
    }
  }
  function insert(uint256[] storage values, uint256 value) internal {
    if(indexOf(values, value) >= values.length){
      values.push(value);
    }
  }
}
