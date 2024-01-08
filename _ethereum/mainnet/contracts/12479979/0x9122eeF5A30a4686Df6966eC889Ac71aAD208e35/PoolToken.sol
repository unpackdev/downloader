// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./Ownable.sol";

import "./IDetailedERC20.sol";

/// @title PoolToken
///
/// @dev This is the contract for the Alchemix PoolToken.
///

contract PoolToken is AccessControl, ERC20("Periodic Organic Order Liason", "POOL") {

  /// @dev The identifier of the role which maintains other roles.
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

  /// @dev The identifier of the role which allows accounts to mint tokens.
  bytes32 public constant MINTER_ROLE = keccak256("MINTER");

  constructor() public {
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(MINTER_ROLE, msg.sender);
    _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
  }

  /// @dev A modifier which checks that the caller has the minter role.
  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "PoolToken: only minter");
    _;
  }

  /// @dev Mints tokens to a recipient.
  ///
  /// This function reverts if the caller does not have the minter role.
  ///
  /// @param _recipient the account to mint tokens to.
  /// @param _amount    the amount of tokens to mint.
  function mint(address _recipient, uint256 _amount) external onlyMinter {
    _mint(_recipient, _amount);
  }
}