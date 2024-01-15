// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Defactor is ERC20, Pausable, Ownable {
  constructor(address treasury) ERC20("Defactor", "FACTR") {
    _mint(treasury, 300000000 * 10**decimals());
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
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
