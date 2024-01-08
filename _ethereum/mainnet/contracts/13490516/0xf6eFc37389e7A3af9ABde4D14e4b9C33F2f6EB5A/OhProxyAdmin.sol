// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./OhSubscriber.sol";
import "./OhUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

/// @title Oh! Finance Proxy Admin
/// @notice Contract used to manage and execute proxy upgrades, controlled by Governance
/// @dev Based on OpenZeppelin Implementation
/// @dev https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v3.4/contracts/proxy/ProxyAdmin.sol
contract OhProxyAdmin is ProxyAdmin, OhSubscriber {
    constructor(address _registry) OhSubscriber(_registry) {
        transferOwnership(governance());
    }
}
