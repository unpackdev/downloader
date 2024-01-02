// SPDX-License-Identifier: MIT

/*
|   _____            _                                    |
|  |  __ \          | |                                   |
|  | |__) |   ___   | |   ___   _ __ ___     ___    ___   |
|  |  ___/   / _ \  | |  / _ \ | '_ ` _ \   / _ \  / __|  |
|  | |      | (_) | | | |  __/ | | | | | | | (_) | \__ \  |
|  |_|       \___/  |_|  \___| |_| |_| |_|  \___/  |___/  |
|                                                         |
|                                                         |
*/

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract Polemos is ERC20, ERC20Permit, ERC20Votes {
  uint256 constant ONE_BILLION = 10**9;

  constructor(address dao) ERC20('Polemos', 'PLMS') ERC20Permit('Polemos') {
    require(dao != address(0), 'invalid DAO');
    _mint(dao, ONE_BILLION * 10**decimals());
  }

  // The following functions are overrides required by Solidity.

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20) {
    super._beforeTokenTransfer(from, to, amount);
  }

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
