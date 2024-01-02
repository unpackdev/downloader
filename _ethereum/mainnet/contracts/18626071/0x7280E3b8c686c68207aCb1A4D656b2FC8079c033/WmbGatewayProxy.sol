// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
/**
 * Wanchain Message Bridge
 * https://wanchain.org/ 
 */

import "./TransparentUpgradeableProxy.sol";

contract WmbGatewayProxy is TransparentUpgradeableProxy {
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}
}
