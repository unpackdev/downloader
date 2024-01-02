// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.4;

import "./TransparentUpgradeableProxy.sol";

contract EthConnectorProxy is TransparentUpgradeableProxy {
    
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable TransparentUpgradeableProxy(_logic, admin_, _data) {}

}