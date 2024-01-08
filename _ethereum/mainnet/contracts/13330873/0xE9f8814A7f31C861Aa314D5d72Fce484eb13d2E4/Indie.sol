// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// 01001001 01001110 01000100 01001001 01000101 

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Pausable.sol";

contract Indie is ERC20, Ownable, ERC20Pausable {
  uint256 private immutable _cap = 10_000_000e18; // 10 Million Supply Cap

  constructor() ERC20('Indie', 'INDIE') {}

  function cap() public pure returns (uint256) {
    return _cap;
  }

  function mint(address to, uint256 amount) public onlyOwner {
    require(ERC20.totalSupply() + amount <= _cap, 'ERC20Capped: cap exceeded');
    _mint(to, amount);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
