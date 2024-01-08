// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./TokenERC20.sol";
import "./PoolCreator.sol";
import "./StakingPool.sol";
import "./RewardManager.sol";

contract StakingPoolFactory is PoolCreator {
    TokenERC20 public tokenERC20;
    RewardManager public rewardManager;

    event PoolCreated(
        address indexed pool,
        uint256 maturityDays,
        uint256 launchTime,
        uint256 poolSize,
        uint256 poolApy
    );

    constructor(TokenERC20 _tokenERC20, RewardManager _rewardManager) {
        tokenERC20 = _tokenERC20;
        rewardManager = _rewardManager;
    }

    function create(
        uint256 maturityDays,
        uint256 launchTime,
        uint256 closingTime,
        uint256 poolSize,
        uint256 poolApy
    ) public onlyPoolCreator returns (address) {
        address newPool =
            address(
                new StakingPool(
                    tokenERC20,
                    this,
                    rewardManager,
                    maturityDays,
                    launchTime,
                    closingTime,
                    poolSize,
                    poolApy
                )
            );

        emit PoolCreated(newPool, maturityDays, launchTime, poolSize, poolApy);

        rewardManager.addPool(newPool);

        return newPool;
    }
}