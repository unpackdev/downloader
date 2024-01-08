// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Cover contract interface. See {Cover}.
 * @author crypto-pumpkin
 * Help convert other types to string
 */
library StringHelper {
  function stringToBytes32(string calldata str) internal pure returns (bytes32 result) {
    bytes memory strBytes = abi.encodePacked(str);
    assembly {
      result := mload(add(strBytes, 32))
    }
  }

  function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
    uint8 i = 0;
    while(i < 32 && _bytes32[i] != 0) {
        i++;
    }
    bytes memory bytesArray = new bytes(i);
    for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
        bytesArray[i] = _bytes32[i];
    }
    return string(bytesArray);
  }

  function uintToString(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    } else {
      bytes32 ret;
      while (_i > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((_i % 10) + 48) * 2 ** (8 * 31));
        _i /= 10;
      }
      _uintAsString = bytes32ToString(ret);
    }
  }
}