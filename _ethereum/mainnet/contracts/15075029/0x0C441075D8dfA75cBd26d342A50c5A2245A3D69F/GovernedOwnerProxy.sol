// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./CommonOwnerProxy.sol";
import "./BridgeOwnerProxy.sol";
import "./MessageOwnerProxy.sol";
import "./SgnOwnerProxy.sol";
import "./UpgradeableOwnerProxy.sol";

contract GovernedOwnerProxy is
    CommonOwnerProxy,
    BridgeOwnerProxy,
    MessageOwnerProxy,
    SgnOwnerProxy,
    UpgradeableOwnerProxy
{
    constructor(address _initializer) OwnerProxyBase(_initializer) {}
}
