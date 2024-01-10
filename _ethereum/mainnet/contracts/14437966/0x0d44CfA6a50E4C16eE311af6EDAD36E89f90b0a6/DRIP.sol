// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;


import "./draft-ERC20PermitUpgradeable.sol";

contract DRIP is ERC20PermitUpgradeable {
  function initialize() public {
    __ERC20Permit_init("DRIP");
    _mint(0x592E10267af60894086d40DcC55Fe7684F8420D5, 100e24);
  }
}
