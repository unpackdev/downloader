/*

  OwnableDelegateProxy

*/
// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes memory data
    ) public {
        require(owner != address(0), "owner: zero address");
        require(
            initialImplementation != address(0),
            "initialImplementation: zero address"
        );
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success, ) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }
}
