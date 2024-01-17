/*

  OwnableDelegateProxy

*/
// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data)
    {
      require(owner != address(0), "Owner cannot be a zero address");
      require(initialImplementation != address(0), " cannot be a zero address"); 
      setUpgradeabilityOwner(owner);
      _upgradeTo(initialImplementation);
      (bool success,) = initialImplementation.delegatecall(data);
      require(success, "OwnableDelegateProxy failed implementation");
    }

}
