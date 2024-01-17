// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

library BytesToString {

  function convert32(bytes32 _bytes32) internal pure returns (string memory) {
          uint c = 0;
          uint i = 0;
          for(i = 0; i < 32; i++) {
              if(_bytes32[i] != 0){
                c+=1;
              }
          }
          bytes memory bytesArray = new bytes(c);
          c = 0;
          for (i = 0; i < 32; i++) {
              if(_bytes32[i] != 0){
                bytesArray[c] = _bytes32[i];
                c += 1;
              }
          }
          return string(bytesArray);
      }
      
    
  function convert8(bytes8 _bytes8) internal pure returns (string memory) {
          uint c = 0;
          uint i = 0;
          for(i = 0; i < 8; i++) {
              if(_bytes8[i] != 0){
                c+=1;
              }
          }
          bytes memory bytesArray = new bytes(c);
          c = 0;
          for (i = 0; i < 8; i++) {
              if(_bytes8[i] != 0){
                bytesArray[c] = _bytes8[i];
                c += 1;
              }
          }
          return string(bytesArray);
      }
}