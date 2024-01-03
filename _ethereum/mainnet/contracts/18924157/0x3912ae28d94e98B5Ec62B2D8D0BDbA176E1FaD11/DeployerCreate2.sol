// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OMM.sol";

contract DeployerCreate2 {

  address private _owner = 0xAE7EFAe157675b66e16cfF44aEaE20B50fb3E423;

  function deploy(uint _amount) public {
    require(msg.sender == _owner);
    bytes32 salt = keccak256(abi.encode(uint(123)));
    new OMM{salt: salt}(_owner, _amount);
  }

}
