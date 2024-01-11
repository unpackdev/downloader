// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
pragma abicoder v2;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

/**
 * This contract is meant to override all state mutating
 * functions of WDoge v1 to ensure they revert.
 */
contract FrozenWDoge is Initializable, ERC20Upgradeable, OwnableUpgradeable {

  /**
   * The contract is frozen and this function cannot be executed at this time.
   */
  error ContractFrozen();

  function isFrozen() external pure returns (bool frozen) {
    return true;
  }

  function transferOwnership(address) public pure override {
    revert ContractFrozen();
  }

  function approve(address, uint256) public pure override returns (bool) {
    revert ContractFrozen();
  }

  function decreaseAllowance(address, uint256) public pure override returns (bool) {
    revert ContractFrozen();
  }

  function increaseAllowance(address, uint256) public pure override returns (bool) {
    revert ContractFrozen();
  }

  function renounceOwnership() public pure override {
    revert ContractFrozen();
  }

  function transfer(address, uint256) public pure override returns (bool) {
    revert ContractFrozen();
  }

  function transferFrom(
    address,
    address,
    uint256
  ) public pure override returns (bool) {
    revert ContractFrozen();
  }

  /**
   * @dev Returns the number of decimals used to get its human representation.
   * Dogecoin has 8 decimals so that's what we use here too.
   */
  function decimals() public pure override returns (uint8) {
    return 8;
  }

  function getVersion() external pure returns (uint256) {
    return 10_001;
  }
}
