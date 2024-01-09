// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./TANSO_v1.sol";

/**
 * @title Basic staking manager for the TANSO token.
 *
 * This contract is for storing and distributing the tokens for the basic staking.
 */
contract TANSOBasicStakingManager_v1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  /**
   * The default constructor of this contract that is inherited from OpenZeppelin Upgradeable Contracts.
   */
  function initialize() initializer public {
    // Initilizes all the parent contracts.
    __Ownable_init();
    __UUPSUpgradeable_init();
  }
  
  /**
   * @custom:oz-upgrades-unsafe-allow constructor
   */
  constructor() initializer {}

  /**
   * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
   *
   * Note that this function is callable only by the owner.
   */
  function _authorizeUpgrade(address) onlyOwner internal override {}

  /**
   * Transfers the tokens for the basic staking from THIS CONTRACT (not from the owner) to the recipient.
   *
   * Note that this function is callable only by the owner.
   *
   * @param token The token contract's address.
   * @param recipient The recipient of the basic staking tokens.
   * @param amount The amount of the basic staking tokens for the recipient.
   */
  function transferBasicStaking(TANSO_v1 token, address recipient, uint256 amount) onlyOwner external {
    token.transfer(recipient, amount);
  }
}
