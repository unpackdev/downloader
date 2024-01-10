//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";

contract WovenExchangeProxy is TransparentUpgradeableProxy {
    // solhint-disable no-empty-blocks

    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

    // solhint-enable no-empty-blocks
}
