/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./Ownable.sol";
import "./Interfaces.sol";

/**
 * @title RegistryAccessor
 * @notice Grants access to store and retrieve data from the protocol Registry
 * @dev Registry value updatable by owner if timelocks match
 */
contract RegistryAccessor is Ownable {
    /**
     * @notice Emitted when {registry} is updated with `newRegistry`
     */
    event RegistryUpdate(address newRegistry);

    /**
     * @notice Address of the Continuous ESDS contract registry
     */
    IRegistry public registry;

    /**
     * @notice Updates the registry contract
     * @dev Owner only - governance hook
     *      If registry is already set, the new registry's timelock must match the current's
     * @param newRegistry New registry contract
     */
    function setRegistry(address newRegistry) public onlyOwner {
        require(newRegistry != address(0), "RegistryAccessor: zero address");
        require(
            (address(registry) == address(0) && Address.isContract(newRegistry)) ||
                IRegistry(newRegistry).timelock() == registry.timelock(),
            "RegistryAccessor: timelocks must match"
        );

        registry = IRegistry(newRegistry);

        emit RegistryUpdate(newRegistry);
    }
}