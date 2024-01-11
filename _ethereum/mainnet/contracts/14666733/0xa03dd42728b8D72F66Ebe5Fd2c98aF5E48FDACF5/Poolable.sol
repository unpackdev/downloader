// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/** @title Poolable.
@dev This contract manage configuration of pools
*/
abstract contract Poolable is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct Pool {
        uint256 lockDuration; // locked timespan
        bool opened; // flag indicating if the pool is open
    }

    // pools mapping
    mapping(uint256 => Pool) private _pools;
    uint256 public poolsLength;

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

    /**
     * @dev Modifier that checks that the now() - `depositDate` is above or equal to the min lock duration for pool at index `poolIndex`
     */
    modifier whenUnlocked(uint256 poolIndex, uint256 depositDate) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        require(
            depositDate < block.timestamp,
            "Poolable: Invalid deposit date"
        );
        require(
            block.timestamp - depositDate >= _pools[poolIndex].lockDuration,
            "Poolable: Not unlocked"
        );
        _;
    }

    /**
     * @notice Initializer
     */
    function __Poolable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Poolable_init_unchained();
    }

    function __Poolable_init_unchained() internal onlyInitializing {}

    function getPool(uint256 poolIndex) public view returns (Pool memory) {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        return _pools[poolIndex];
    }

    function addPool(Pool calldata pool) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 poolIndex = poolsLength;

        _pools[poolIndex] = Pool({
            lockDuration: pool.lockDuration,
            opened: pool.opened
        });
        poolsLength = poolsLength + 1;

        emit PoolAdded(poolIndex, _pools[poolIndex]);
    }

    function updatePool(uint256 poolIndex, Pool calldata pool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(poolIndex < poolsLength, "Poolable: Invalid poolIndex");
        Pool storage editedPool = _pools[poolIndex];

        editedPool.lockDuration = pool.lockDuration;
        editedPool.opened = pool.opened;

        emit PoolUpdated(poolIndex, editedPool);
    }

    uint256[50] private __gap;
}
