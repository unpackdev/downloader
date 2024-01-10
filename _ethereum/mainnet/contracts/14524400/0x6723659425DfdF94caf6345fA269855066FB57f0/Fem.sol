// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

/// @custom:security-contact Twitter: @femboydao / Discord: 0xFem#1337 / Email: security@femboydao.com
contract Fem is ERC20, Ownable, ERC20Permit, ERC20Votes {
  constructor() ERC20('FemboyDAO', 'FEM') ERC20Permit('FemboyDAO') {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) public virtual onlyOwner {
    _burn(from, amount);
  }

  // The following functions are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
    super._burn(account, amount);
  }
}
