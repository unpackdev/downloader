pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "./TransparentUpgradeableProxy.sol";

contract DeltaRewardPoolProxy is TransparentUpgradeableProxy {
    constructor(
        address _implementation,
        bytes memory _data
    ) TransparentUpgradeableProxy(_implementation, msg.sender, _data) {}

    // Allow anyone to view the implementation address
    function proxyImplementation() external view returns (address) {
        return _implementation();
    }

    function proxyAdmin() external view returns (address) {
        return _admin();
    }
}
