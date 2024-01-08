// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./TransparentUpgradeableProxy.sol";

/**
 * @title Proxy for Zap.
 */
contract ZapProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data) payable {}
}