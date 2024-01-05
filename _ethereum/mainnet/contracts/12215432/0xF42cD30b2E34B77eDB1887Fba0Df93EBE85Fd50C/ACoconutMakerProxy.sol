// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./TransparentUpgradeableProxy.sol";

/**
 * @title Proxy for ACoconut Maker.
 */
contract ACoconutMakerProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data) payable {}
}