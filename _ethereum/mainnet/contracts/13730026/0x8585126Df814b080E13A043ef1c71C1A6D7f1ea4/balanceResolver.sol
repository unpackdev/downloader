// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./TransparentUpgradeableProxy.sol";

contract InteropBalanceResolverProxy is TransparentUpgradeableProxy {
    constructor(address _logic, bytes memory _data)
        TransparentUpgradeableProxy(_logic, msg.sender, _data)
    {}
}
