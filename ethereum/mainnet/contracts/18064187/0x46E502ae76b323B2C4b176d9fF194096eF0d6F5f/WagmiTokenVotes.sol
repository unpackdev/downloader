// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";

contract WagmiTokenVotes is ERC20, ERC20Snapshot, Ownable {
  constructor() ERC20("Wagmi Token Votes", "WTV") {}

  function snapshot() public onlyOwner {
    _snapshot();
  }

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Snapshot) {
    super._beforeTokenTransfer(from, to, amount);
  }
}
