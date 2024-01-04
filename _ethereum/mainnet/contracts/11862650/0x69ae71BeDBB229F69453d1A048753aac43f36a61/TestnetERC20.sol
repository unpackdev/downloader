// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import "./ERC20.sol";

contract TestnetERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) public ERC20(_name, _symbol) {
    _setupDecimals(_decimals);
  }

  function allocateTo(address ownerAddress, uint256 value) external {
    _mint(ownerAddress, value);
  }
}
