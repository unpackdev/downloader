pragma solidity 0.5.8;

contract Bytes32 {
  function _bytes32(string memory _input) internal pure returns (bytes32 result) {
    assembly {
      result := mload(add(_input, 32))
    }
  }
}
