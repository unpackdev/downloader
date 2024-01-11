//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

/**
 * Interface for Liquidity Mining Terminal for Solidity integration
 */
interface ILMTerminal {
    function clrDeployer() external view returns (address);

    function customDeploymentFee(address) external view returns (uint256);

    function customDeploymentFeeEnabled(address) external view returns (bool);

    function deployIncentivizedPool(
        string memory symbol,
        PositionTicks memory ticks,
        RewardsProgram memory rewardsProgram,
        PoolDetails memory pool
    ) external;

    function deployUniswapPool(
        address token0,
        address token1,
        uint24 fee,
        uint160 initPrice
    ) external returns (address pool);

    function deployedCLRPools(uint256) external view returns (address);

    function deploymentFee() external view returns (uint256);

    function disableCustomDeploymentFee(address deployer) external;

    function enableCustomDeploymentFee(address deployer, uint256 feeAmount)
        external;

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address pool);

    function initialize(
        address _xTokenManager,
        address _rewardEscrow,
        address _proxyAdmin,
        address _clrDeployer,
        address _uniswapFactory,
        UniswapContracts memory _uniContracts,
        uint256 _deploymentFee,
        uint256 _rewardFee,
        uint256 _tradeFee
    ) external;

    function initiateNewRewardsProgram(
        address clrPool,
        uint256[] memory totalRewardAmounts,
        uint256 rewardsDuration
    ) external;

    function initiateRewardsProgram(
        address clrPool,
        uint256[] memory totalRewardAmounts,
        uint256 rewardsDuration
    ) external;

    function owner() external view returns (address);

    function positionManager() external view returns (address);

    function proxyAdmin() external view returns (address);

    function renounceOwnership() external;

    function rewardEscrow() external view returns (address);

    function rewardFee() external view returns (uint256);

    function tradeFee() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function uniContracts()
        external
        view
        returns (
            address router,
            address quoter,
            address _positionManager
        );

    function uniswapFactory() external view returns (address);

    function withdrawFees(address token) external;

    function xTokenManager() external view returns (address);

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool);

    struct UniswapContracts {
        address router;
        address quoter;
        address positionManager;
    }

    struct PositionTicks {
        int24 lowerTick;
        int24 upperTick;
    }

    struct RewardsProgram {
        address[] rewardTokens;
        uint256 duration;
        uint256 vestingPeriod;
    }

    struct PoolDetails {
        uint24 fee;
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
    }
}
