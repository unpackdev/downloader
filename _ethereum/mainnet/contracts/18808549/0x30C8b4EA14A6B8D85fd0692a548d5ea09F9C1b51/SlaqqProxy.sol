// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.7;

import "./TransparentUpgradeableProxy.sol";

/**
 * @title SlaqqProxy
 * @notice Proxy contract that forwards calls to the main contract.
 * @dev Allows for upgrading the logic contract without changing the proxys address.
 */

contract SlaqqProxy is 
    TransparentUpgradeableProxy
{   
    /**
     * @notice The constructor of the proxy that sets the admin and logic.
     * @param logic: The address of the contract that implements the underlying logic.
     * @param admin: The address of the admin of the proxy.
     * @param data: Any data to send immediately to the implementation contract.
     */
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(
        logic, 
        admin, 
        data
    ) {}
}
