// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./Ownable.sol";

interface ISmartWalletChecker {
  function check(address addr) external view returns (bool);
}

/**
 * @title Smart Wallet Checker implementation.
 * @notice Checks if an address is approved for staking.
 * @dev This is a basic implementation using a mapping for address => bool.
 * @dev This contract does not check if the address is a contract or not.
 * @dev This contract is a modified version of
 * https://github.com/Idle-Finance/idle-staking/blob/master/contracts/smartWalletChecker/SmartWalletChecker.sol
 */
contract SmartWalletChecker is Ownable, ISmartWalletChecker {
  // @dev mapping of allowed addresses
  mapping(address => bool) private _enabledAddresses;
  // @dev Checks if any contract is allowed.
  bool public isOpen;

  /**
   * @notice Enables an address
   * @dev only callable by owner.
   * @dev This does not check if the address is actually a smart contract or not.
   * @param addr The contract address to enable.
   */
  function toggleAddress(address addr, bool _enabled) external onlyOwner {
    _enabledAddresses[addr] = _enabled;
  }

  /**
   * @notice Allow any non EOA to interact with stkIDLE contract.
   * @dev only callable by owner.
   * @dev Once isOpen is set to true, it cannot be set to false without locking users in so be careful.
   * @param _open Wheter to allow or not anyone
   */
  function toggleIsOpen(bool _open) external onlyOwner {
    isOpen = _open;
  }

  /**
   * @notice Check an address
   * @dev This method will be called by the VotingEscrow contract.
   * @param addr The contract address to check.
   */
  function check(address addr) external view override returns (bool) {
    return isOpen || _enabledAddresses[addr];
  }
}
