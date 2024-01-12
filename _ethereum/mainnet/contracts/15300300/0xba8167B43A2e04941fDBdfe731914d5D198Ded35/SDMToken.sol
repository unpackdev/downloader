// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC20Votes.sol";

contract SDMToken is ERC20Votes {
  uint256 public maxSupply = 1000;

  constructor() ERC20("SDMToken", "SDM") ERC20Permit("SDMToken") {
    _mint(msg.sender, maxSupply * (10**uint256(decimals())));
  }

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount)
    internal
    override(ERC20Votes)
  {
    super._burn(account, amount);
  }
}
