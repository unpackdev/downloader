// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

import "./ProxyAdmin.sol";
import "./TransparentUpgradeableProxy.sol";

/// @title A proxy for the CiliProxy contract
/// @notice The proxy allows to change the implementation and keep the same address and storage.
/// @dev This contract is used for upgrading
contract CiliProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address _admin,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, _admin, _data) {}
}