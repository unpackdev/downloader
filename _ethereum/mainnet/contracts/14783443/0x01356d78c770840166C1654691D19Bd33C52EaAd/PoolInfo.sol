/*
PoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "./IPoolInfo.sol";
import "./IPool.sol";
import "./IStakingModule.sol";
import "./IRewardModule.sol";
import "./IStakingModuleInfo.sol";
import "./IRewardModuleInfo.sol";
import "./OwnerController.sol";

/**
 * @title Pool info library
 *
 * @notice this implements the Pool info library, which provides read-only
 * convenience functions to query additional information and metadata
 * about the core Pool contract.
 */

contract PoolInfo is IPoolInfo, OwnerController {
    mapping(address => address) public registry;

    /**
     * @inheritdoc IPoolInfo
     */
    function modules(address pool)
        public
        view
        override
        returns (
            address,
            address,
            address,
            address
        )
    {
        IPool p = IPool(pool);
        IStakingModule s = IStakingModule(p.stakingModule());
        IRewardModule r = IRewardModule(p.rewardModule());
        return (address(s), address(r), s.factory(), r.factory());
    }

    /**
     * @notice register factory to info module
     * @param factory address of factory
     * @param info address of info module contract
     */
    function register(address factory, address info) external onlyController {
        registry[factory] = info;
    }

    /**
     * @inheritdoc IPoolInfo
     */
    function rewards(address pool, address addr)
        public
        view
        override
        returns (uint256[] memory rewards_)
    {
        address stakingModule;
        address rewardModule;
        address stakingModuleType;
        address rewardModuleType;

        (
            stakingModule,
            rewardModule,
            stakingModuleType,
            rewardModuleType
        ) = modules(pool);

        IStakingModuleInfo stakingModuleInfo =
            IStakingModuleInfo(registry[stakingModuleType]);
        IRewardModuleInfo rewardModuleInfo =
            IRewardModuleInfo(registry[rewardModuleType]);

        uint256 shares = stakingModuleInfo.shares(stakingModule, addr, 0);

        if (shares == 0)
            return new uint256[](IPool(pool).rewardTokens().length);

        return rewardModuleInfo.rewards(rewardModule, addr, shares);
    }
}
