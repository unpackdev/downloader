// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "./TransparentUpgradeableProxy.sol";

/// @title    AvoSignersListProxy
/// @notice   Default ERC1967Proxy for AvoSignersList
contract AvoSignersListProxy is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) payable TransparentUpgradeableProxy(logic_, admin_, data_) {}
}
