//SPDX-License-Identifier: GNU General Public License v3.0
pragma solidity ^0.8.0;

library NumberHelper {
  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function daysSince(uint256 _activeDateTime, uint256 _interval) internal view returns (uint256) {
    unchecked {
      uint256 passedTime = (block.timestamp - _activeDateTime) / _interval;
      if(passedTime <= 6) {
        return 0;
      } else if( passedTime <= 24) {
        return 1;
      } else if( passedTime <= 48 ) {
        return 2;
      } else if( passedTime <=72 ) {
        return 3;
      } else if( passedTime <= 96 ) {
        return 4;
      } else if( passedTime <= 120 ) {
        return 5;
      } else if( passedTime <= 144 ) {
        return 6;
      } else if( passedTime <= 168 ) {
        return 7;
      } else {
        return 8;
      }
    }
  }
}
