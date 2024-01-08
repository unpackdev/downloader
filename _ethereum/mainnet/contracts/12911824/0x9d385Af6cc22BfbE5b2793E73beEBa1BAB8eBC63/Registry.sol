// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./OwnableUpgradeable.sol";
import "./RegistryInterface.sol";

contract Registry is OwnableUpgradeable, RegistryInterface {
  address private pointer;

  event Registered(address indexed pointer);

  constructor (address _pointer) public {
    pointer = _pointer;
    __Ownable_init();
  }

  function register(address _pointer) external onlyOwner {
    pointer = _pointer;
    emit Registered(pointer);
  }

  function lookup() external override view returns (address) {
    return pointer;
  }
}
