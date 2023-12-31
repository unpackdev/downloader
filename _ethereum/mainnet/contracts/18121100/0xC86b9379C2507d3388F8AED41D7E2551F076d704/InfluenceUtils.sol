// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library InfluenceUtils {
  function strToUint(string memory _str) pure internal returns(uint256 res) {
    bytes memory b = bytes(_str);
    for(uint i=0; i < b.length; i++) {
      res = res + uint(uint8(b[i]))*(2**(8*(b.length-(i+1))));
    }
    return res;
  }

  function packFeatures(uint256[6] memory values) pure internal returns (uint256 packed){
    packed = values[0];
    packed |= values[1] << 32;
    packed |= values[2] << 64;
    packed |= values[3] << 96;
    packed |= values[4] << 128;
    packed |= values[5] << 160;
    return packed;
  }
}
