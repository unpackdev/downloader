// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./EnumerableSet.sol";
import "./IPoolRegistry.sol";
import "./IMasterOracle.sol";

abstract contract PoolRegistryStorageV1 is IPoolRegistry {
    /**
     * @notice Pools collection
     */
    EnumerableSet.AddressSet internal pools;

    /**
     * @notice Prices oracle
     */
    IMasterOracle public masterOracle;

    /**
     * @notice Fee collector address
     */
    address public feeCollector;
}
