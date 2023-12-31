pragma solidity ^0.5.17;

contract Factory {

  function deploy(bytes memory data, uint256 salt) public {
    assembly {
      pop(create2(0, add(data, 32), mload(data), salt))
    }
  }

}