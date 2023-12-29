// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";

/**
 * @title Secondary
 * @dev A Secondary contract can only be used by its Limited Owner account (the one that created it / not KARMATokenDeployer)
 */
contract LimitedOwner is OwnableUpgradeable {
  address private _limitedOwner;
  address public karmaCampaignFactory;

  event LimitedOwnerTransferred(
    address recipient
  );

  /**
   * @dev Reverts if called from any account other than the LimitedOwner.
   */
  modifier onlyLimitedOrOwner() { 
    require(msg.sender == _limitedOwner || msg.sender == karmaCampaignFactory || msg.sender == owner());
    _;
  }

  /**
   * @return the address of the Limited Owner.
   */
  function limitedOwner() public view returns (address) {
    return _limitedOwner;
  }
  
  /**
   * @dev Transfers contract to a new Limited Owner.
   * @param recipient The address of new Limited Owner. 
   */
  function transferLimitedOwner(address recipient) public onlyLimitedOrOwner {
    require(recipient != address(0));
    _limitedOwner = recipient;
    emit LimitedOwnerTransferred(_limitedOwner);
  }
}