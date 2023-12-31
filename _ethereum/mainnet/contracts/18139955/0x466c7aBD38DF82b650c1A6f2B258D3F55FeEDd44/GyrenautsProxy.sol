// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./TransparentUpgradeableProxy.sol";

contract GyrenautsProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _admin, bytes memory _data) TransparentUpgradeableProxy(_logic, _admin, _data) {}

    function upgradeTo(address newImplementation) external {
        require(msg.sender == _admin(), "GyrenautsProxy: caller is not the admin");
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable {
        require(msg.sender == _admin(), "GyrenautsProxy: caller is not the admin");
        _upgradeToAndCall(newImplementation, data, false);
    }

    function implementation() external view returns (address) {
        return _implementation();
    }
}
