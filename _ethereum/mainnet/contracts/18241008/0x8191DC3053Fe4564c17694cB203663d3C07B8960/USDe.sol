// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./draft-ERC20Permit.sol";
import "./AccessControlEnumerable.sol";
import "./Context.sol";
import "./IUSDe.sol";

/**
 * @title USDe
 * @notice Stable Coin Contract
 * @dev Only approved contracts will have `MINTER_ROLE` to mint tokens
 */
contract USDe is Context, AccessControlEnumerable, ERC20Burnable, ERC20Permit {
  bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

  constructor(address admin) ERC20('USDe', 'USDe') ERC20Permit('USDe') {
    require(admin != address(0), 'Zero address not valid');
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
    _mint(to, amount);
  }
}
