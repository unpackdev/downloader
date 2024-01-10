// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./IRegistry.sol";

import "./RoleCheckable.sol";

contract RegistryStorage is RoleCheckable {
    IRegistry internal registry;

    event RegistryChanged(IRegistry _registry);

    /* User Methods */

    /**
     * @notice Setter for the registry address
     * @param _registry the address of the new registry
     */
    function setRegistry(IRegistry _registry) external onlyAdmin {
        registry = _registry;
        emit RegistryChanged(_registry);
    }
}
