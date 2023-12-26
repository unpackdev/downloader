// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TransparentUpgradeableProxy.sol";

contract QuirklingsV2 is TransparentUpgradeableProxy {
    constructor(
        address logic_,
        address admin_,
        bytes memory data_
    ) TransparentUpgradeableProxy(logic_, admin_, data_) {}
}
