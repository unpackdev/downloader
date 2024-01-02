pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./TransparentUpgradeableProxy.sol";

contract DeltaBRC20LuckyPoolProxy is TransparentUpgradeableProxy {
    constructor(
        address _implementation,
        address _admin,
        bytes memory _data
    ) TransparentUpgradeableProxy(_implementation, _admin, _data) {}

    // Allow anyone to view the implementation address
    function proxyImplementation() external view returns (address) {
        return _implementation();
    }

    function proxyAdmin() external view returns (address) {
        return _admin();
    }
}
