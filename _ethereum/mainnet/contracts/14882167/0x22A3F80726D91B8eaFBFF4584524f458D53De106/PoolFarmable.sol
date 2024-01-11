// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

/** @title PoolFarmable.
@dev This contract manage configuration of farm pools
*/
abstract contract PoolFarmable is Initializable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint256;

    struct FarmPool {
        bool opened;
        int256 minTier;
        uint256 maxTotalDepositAmount;
        uint256 maxUserDepositAmount;
        uint256 minDepositDuration; // in seconds
        uint256 maxDepositDuration; // in seconds
        uint256 interestNumerator; // interest per seconds
        uint256 interestDenominator; // interest per seconds
    }

    // pools
    FarmPool[] private _pools;

    /**
     * @dev Emitted when a pool is created
     */
    event FarmPoolAdd(uint256 poolIndex, FarmPool pool);

    /**
     * @dev Emitted when a pool is updated
     */
    event FarmPoolUpdate(uint256 poolIndex, FarmPool pool);

    /**
     * @dev Modifier that checks pool is valid
     */
    modifier checkFarmPool(FarmPool calldata pool) {
        require(
            pool.maxUserDepositAmount <= pool.maxTotalDepositAmount,
            "PoolFarmable: maxUserDepositAmount must be less than or equal to maxTotalDepositAmount"
        );

        require(
            pool.minDepositDuration <= pool.maxDepositDuration,
            "PoolFarmable: minDepositDuration must be less than or equal to maxDepositDuration"
        );

        require(
            pool.interestNumerator > 0,
            "PoolFarmable: interestNumerator must be greater than 0"
        );

        require(
            pool.interestDenominator > 0,
            "PoolFarmable: interestDenominator must be greater than 0"
        );

        require(
            pool.interestNumerator <= pool.interestDenominator,
            "PoolFarmable: interestNumerator must be less than or equal to interestDenominator"
        );

        _;
    }

    /**
     * @dev Modifier that checks pool index is valid
     */
    modifier checkFarmPoolIndex(uint256 poolIndex) {
        require(poolIndex < _pools.length, "PoolFarmable: Invalid poolIndex");
        _;
    }

    /**
     * @notice Initializer
     */
    function __PoolFarmable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __PoolFarmable_init_unchained();
    }

    /**
     * @notice Initializer
     */
    function __PoolFarmable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Return a pool from its index
     */
    function getFarmPool(uint256 poolIndex)
        public
        view
        checkFarmPoolIndex(poolIndex)
        returns (FarmPool memory)
    {
        return _pools[poolIndex];
    }

    /**
     * @dev Return the number of pools
     */
    function farmPoolsLength() public view returns (uint256) {
        return _pools.length;
    }

    /**
     * @dev Add a new pool
     */
    function addFarmPool(FarmPool calldata pool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkFarmPool(pool)
    {
        _pools.push(pool);

        emit FarmPoolAdd(_pools.length - 1, _pools[_pools.length - 1]);
    }

    /**
     * @dev Update an existing pool
     */
    function updateFarmPool(uint256 poolIndex, FarmPool calldata pool)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        checkFarmPoolIndex(poolIndex)
        checkFarmPool(pool)
    {
        FarmPool storage editedPool = _pools[poolIndex];

        editedPool.opened = pool.opened;
        editedPool.minTier = pool.minTier;
        editedPool.maxTotalDepositAmount = pool.maxTotalDepositAmount;
        editedPool.maxUserDepositAmount = pool.maxUserDepositAmount;
        editedPool.minDepositDuration = pool.minDepositDuration;
        editedPool.maxDepositDuration = pool.maxDepositDuration;
        editedPool.interestNumerator = pool.interestNumerator;
        editedPool.interestDenominator = pool.interestDenominator;

        emit FarmPoolUpdate(poolIndex, editedPool);
    }

    uint256[50] private __gap;
}
