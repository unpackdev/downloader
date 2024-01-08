// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./OwnableUpgradeable.sol";

contract Series is OwnableUpgradeable {

  string private name;
  mapping(address=>address[]) plugins;

  function initialize(address owner_, string memory name_) public initializer {
    __Ownable_init();
    transferOwnership(owner_);
    name = name_;
  }

  function getName() public view returns (string memory) {
    return name;
  }
}
