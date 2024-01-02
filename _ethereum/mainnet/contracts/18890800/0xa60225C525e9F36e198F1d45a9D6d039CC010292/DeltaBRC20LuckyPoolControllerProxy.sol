pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./TransparentUpgradeableProxy.sol";

contract DeltaBRC20LuckyPoolControllerProxy is TransparentUpgradeableProxy {
    constructor(
        address _implementation,
        bytes memory _data
    ) TransparentUpgradeableProxy(_implementation, 0x72A7E0764A06697d8755048Ccec37A37106e4798, _data) {}

    // Allow anyone to view the implementation address
    function proxyImplementation() external view returns (address) {
        return _implementation();
    }

    function proxyAdmin() external view returns (address) {
        return _admin();
    }
}
