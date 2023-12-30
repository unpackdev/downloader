// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;

import "./Initializable.sol";

contract Simple2 is Initializable{

  uint256 value;

  function initialize(uint256 _value) public initializer {
        value = _value;
    }

  function setValue(uint256 _value) external {
    value = _value;
  }

  function getValue() external view returns (uint256) {
    return value;
  }

}
