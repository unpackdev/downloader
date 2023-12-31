// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeMathUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract FTokenMigrator is ERC20Upgradeable {

  /// @dev The owner of the new version, which is also the treasury address of the old version
  address private _owner;

  /// @dev The nav of the old version, new version will not use it
  uint256 private _oldNav;

  /// @dev The gap list of OwnableUpgradeable in StakingHook
  uint256[48] private __ownerGap;

  /// @dev The staking contract address of the new version
  address public staking;

  /// @dev The gap list of StakingHook
  uint256[49] private __stakingHookGap;

  /// @dev The address of treasury in FractionalToken
  address public treasury;

  /// @dev The number of nav in FractionalToken
  uint256 public nav;

  /// @notice Migrate variables
  /// @param owner the owner of OwnableUpgradeable.
  function migrate(address owner) external {
    // stash store variables of old versions
    address _treasury = _owner;

    // migrate variables of old version to new locations
    treasury = _treasury;
    nav = _oldNav;

    // overwrite the variables of the old version with the variables of the new version
    _owner = owner;
  }
}
