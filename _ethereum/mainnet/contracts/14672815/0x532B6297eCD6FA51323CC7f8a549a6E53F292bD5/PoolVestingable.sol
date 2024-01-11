// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/** @title PoolVestingable.
@dev This contract manage configuration of vesting pools
*/
abstract contract PoolVestingable is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct VestingPool {
        uint256[] timestamps; // Timestamp at which the associated ratio is available.
        uint256[] ratiosPerHundredThousand; // Ratio of initial amount to be available at the associated timestamp in / 100,000 (100% = 100,000, 1% = 1,000)
    }

    // pools
    VestingPool[] private _pools;

    /**
     * @dev Emitted when a pool is created
     */
    event VestingPoolAdded(uint256 poolIndex, VestingPool pool);

    /**
     * @dev Emitted when a pool is updated
     */
    event VestingPoolUpdated(uint256 poolIndex, VestingPool pool);

    /**
     * @dev Modifier that checks pool is valid
     */
    modifier checkVestingPool(VestingPool calldata pool) {
        // check length of timestamps and ratiosPerHundredThousand are equal
        require(
            pool.timestamps.length == pool.ratiosPerHundredThousand.length,
            "PoolVestingable: Number of timestamps is not equal to number of ratios"
        );

        // check the timestamps are increasing
        // start at i = 1
        for (uint256 i = 1; i < pool.timestamps.length; i++) {
            require(
                pool.timestamps[i - 1] < pool.timestamps[i],
                "PoolVestingable: Timestamps be asc ordered"
            );
        }

        // check sum of ratios = 100,000
        uint256 totalRatio = 0;
        for (uint256 i = 0; i < pool.ratiosPerHundredThousand.length; i++) {
            totalRatio = totalRatio.add(pool.ratiosPerHundredThousand[i]);
        }
        require(
            totalRatio == 100000,
            "PoolVestingable: Sum of ratios per thousand must be equal to 100,000"
        );

        _;
    }

    /**
     * @notice Initializer
     */
    function __PoolVestingable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __PoolVestingable_init_unchained();
    }

    function __PoolVestingable_init_unchained() internal onlyInitializing {}

    function getVestingPool(uint256 poolIndex)
        public
        view
        returns (VestingPool memory)
    {
        require(
            poolIndex < _pools.length,
            "PoolVestingable: Invalid poolIndex"
        );
        return _pools[poolIndex];
    }

    function vestingPoolsLength() public view returns (uint256) {
        return _pools.length;
    }

    function addVestingPool(VestingPool calldata pool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkVestingPool(pool)
    {
        _pools.push(
            VestingPool({
                timestamps: pool.timestamps,
                ratiosPerHundredThousand: pool.ratiosPerHundredThousand
            })
        );

        emit VestingPoolAdded(_pools.length - 1, _pools[_pools.length - 1]);
    }

    function updateVestingPool(uint256 poolIndex, VestingPool calldata pool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkVestingPool(pool)
    {
        require(
            poolIndex < _pools.length,
            "PoolVestingable: Invalid poolIndex"
        );
        VestingPool storage editedPool = _pools[poolIndex];

        editedPool.timestamps = pool.timestamps;
        editedPool.ratiosPerHundredThousand = pool.ratiosPerHundredThousand;

        emit VestingPoolUpdated(poolIndex, editedPool);
    }

    uint256[50] private __gap;
}
