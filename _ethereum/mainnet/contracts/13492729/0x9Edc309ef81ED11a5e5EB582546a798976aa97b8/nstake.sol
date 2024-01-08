// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


/// @title Nummus
///
/// @dev This is the token contract for nummus.finance staking token representation.

contract nstake is AccessControl, ERC20 {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");


  event Paused(address minter, bool state);

  constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param recipient the account to mint tokens to.
  /// @param amount    the amount of tokens to mint.
  function mint(address recipient, uint256 amount) external onlyRole(MINTER_ROLE) {
     _mint(recipient, amount);
  }

  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

  /// @dev Destroys `amount` tokens from `account`, deducting from the caller's allowance.
  ///
  /// @param account the account to burn tokens from.
  /// @param amount  the amount of tokens to burn.
  function burnFrom(address account, uint256 amount) external {
    uint256 newAllowance = allowance(account, _msgSender()).sub(amount, "Nummus: burn amount exceeds allowance");

    _approve(account, _msgSender(), newAllowance);
    _burn(account, amount);
  }

}
