// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./EnumerableSet.sol";
import "./IPoolRegistry.sol";

abstract contract PoolRegistryStorageV1 is IPoolRegistry {
    /**
     * @notice Pools collection
     */
    EnumerableSet.AddressSet internal pools;

    /**
     * @notice Prices' oracle
     */
    IMasterOracle public override masterOracle;

    /**
     * @notice Fee collector address
     */
    address public override feeCollector;

    /**
     * @notice Native token gateway address
     */
    address public override nativeTokenGateway;

    /**
     * @notice Map of the ids of the pools
     */
    mapping(address => uint256) public override idOfPool;

    /**
     * @notice Counter of ids of the pools
     */
    uint256 public override nextPoolId;

    /**
     * @notice Swapper contract
     */
    ISwapper public swapper;
}

abstract contract PoolRegistryStorageV2 is PoolRegistryStorageV1 {
    /**
     * @notice The Quoter contract
     */
    IQuoter public quoter;

    /**
     * @notice The Cross-chain dispatcher contract
     */
    ICrossChainDispatcher public crossChainDispatcher;
}

abstract contract PoolRegistryStorageV3 is PoolRegistryStorageV2 {
    /**
     * @notice Flag that pause/unpause all cross-chain flash repay operations
     */
    bool public isCrossChainFlashRepayActive;
}
