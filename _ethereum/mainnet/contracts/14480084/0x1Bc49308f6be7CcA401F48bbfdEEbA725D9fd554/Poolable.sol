// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";

/** @title Poolable.
@dev This contract manage configuration of pools
*/
abstract contract Poolable is Ownable {
    struct RewardConfiguration {
        uint256 duration;
        uint256 reward;
    }

    struct Pool {
        bool opened; // flag indicating if the pool is open
        address collection; // NFT collection
        uint256 minDuration; // min deposit timespan
        RewardConfiguration[] rewards; // ordered list of rewards per time
    }

    // pools mapping
    uint256 public poolsLength;
    mapping(uint256 => Pool) private _pools;

    /**
     * @dev Emitted when a pool is created
     */
    event PoolAdded(uint256 poolIndex, Pool pool);

    /**
     * @dev Emitted when a pool is updated
     */
    event PoolUpdated(uint256 poolIndex, Pool pool);

    /**
     * @dev Modifier that checks that the pool at index `poolIndex` is open
     */
    modifier whenPoolOpened(uint256 poolIndex) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(_pools[poolIndex].opened, "Poolable: Pool is closed");
        _;
    }

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex];
    }

    function addPool(Pool calldata pool) external onlyOwner {
        uint256 poolIndex = poolsLength;

        _pools[poolIndex] = pool;
        poolsLength = poolsLength + 1;

        emit PoolAdded(poolIndex, _pools[poolIndex]);
    }

    function updatePool(uint256 poolIndex, Pool calldata pool) external onlyOwner {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(_pools[poolIndex].collection == pool.collection, "Poolable: Invalid collection");
        _pools[poolIndex] = pool;

        emit PoolUpdated(poolIndex, _pools[poolIndex]);
    }

    function closePool(uint256 poolIndex) external onlyOwner {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(_pools[poolIndex].opened, "Poolable: Pool not opened");
        _pools[poolIndex].opened = false;

        emit PoolUpdated(poolIndex, _pools[poolIndex]);
    }

    function isUnlockable(uint256 poolIndex, uint256 depositDate) internal view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(depositDate <= block.timestamp, "Poolable: Invalid deposit date");
        return block.timestamp - depositDate >= _pools[poolIndex].minDuration;
    }

    function isPoolOpened(uint256 poolIndex) public view returns (bool) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].opened;
    }

    function poolCollection(uint256 poolIndex) public view returns (address) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex].collection;
    }

    function getPendingRewards(uint256 poolIndex, uint256 depositDate) internal view returns (uint256, uint256) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        uint256 rewards = 0;
        uint256 date = depositDate;
        for (uint256 i = 0; i < _pools[poolIndex].rewards.length; i++) {
            date = depositDate + _pools[poolIndex].rewards[i].duration;
            if (date > block.timestamp) return (rewards, date);
            rewards += _pools[poolIndex].rewards[i].reward;
        }
        return (rewards, date);
    }
}
