// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./MixinAddressResolver.sol";

/**
 * @notice Implements migration module to build caches of contract address from `AddressResolver.sol`
 * in the contract that is inherited `MixinAddressResolver.sol`.
 *
 * This contract is used only in the following cases.
 * - The case of the initial deployment of the contract.
 * - The case when some contract needs to deploy a new proxy contract.
 */
contract MigrationAddressResolver {
    function buildCaches(address[] calldata _addresses) external {
        for (uint256 i; i < _addresses.length; i++) {
            MixinAddressResolver destination = MixinAddressResolver(_addresses[i]);
            if (!destination.isResolverCached()) {
                destination.buildCache();
            }
        }
    }
}
