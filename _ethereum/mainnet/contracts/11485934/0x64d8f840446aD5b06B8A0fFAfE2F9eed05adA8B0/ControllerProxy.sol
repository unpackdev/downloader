// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./AdminUpgradeabilityProxy.sol";

/**
 * @notice Proxy for Controller to help truffle deployment.
 */
contract ControllerProxy is AdminUpgradeabilityProxy {
    constructor(address _logic, address _admin) AdminUpgradeabilityProxy(_logic, _admin) public payable {}
}