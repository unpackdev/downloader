// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

library ConvertUtils {
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  function bytes32ToAddress(bytes32 _bytes) internal pure returns (address) {
    return address(uint160(uint256(_bytes)));
  }

  function uint256ToBytes32(uint256 _num) internal pure returns (bytes32) {
    return bytes32(_num);
  }

  function bytes32ToUint256(bytes32 _bytes) internal pure returns (uint256) {
    return uint256(_bytes);
  }

  function uint256ArrayToBytes32Array(uint256[] memory _array) internal pure returns (bytes32[] memory) {
    bytes32[] memory out = new bytes32[](_array.length);
    for (uint256 i = 0; i < _array.length; i++) {
      out[i] = uint256ToBytes32(_array[i]);
    }
    return out;
  }
}
