// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IOrchestrator {
    function detonate() external;
}

interface IPCVDepositOrchestrator is IOrchestrator {
    function init(
        address core,
        address pool,
        address nft,
        address router,
        address oraclePool,
        uint32 twapDuration,
        bool isPrice0,
        int24 tickLower,
        int24 tickUpper
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IUSDCPCVDepositOrchestrator is IOrchestrator {
    function init(
        address core,
        address pool,
        address nft,
        address router,
        uint32 twapDuration,
        int24 tickLower,
        int24 tickUpper
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IBondingCurveOrchestrator is IOrchestrator {
    function init(
        address core,
        address uniswapOracle,
        address erc20UniswapPCVDeposit,
        uint256 bondingCurveIncentiveDuration,
        uint256 bondingCurveIncentiveAmount,
        address tokenAddress
    ) external returns (address erc20BondingCurve);
}

interface IControllerOrchestrator is IOrchestrator {
    function init(
        address core,
        address oracle,
        address erc20UniswapPCVDeposit,
        address pool,
        address nft,
        address router,
        uint256 reweightIncentive,
        uint256 reweightMinDistanceBPs
    ) external returns (address erc20UniswapPCVController);
}

interface IIDOOrchestrator is IOrchestrator {
    function init(
        address core,
        address admin,
        address ring,
        address pool,
        address nft,
        address router,
        uint256 releaseWindowDuration
    ) external returns (address ido, address timelockedDelegator);
}

interface IGenesisOrchestrator is IOrchestrator {
    function init(
        address core,
        address ido
    ) external returns (address genesisGroup);
}

interface IStakingOrchestrator is IOrchestrator {
    function init(
        address core,
        address rusd,
        address ring,
        uint stakingDuration,
        uint dripFrequency,
        uint incentiveAmount
    ) external returns (address stakingRewards, address distributor);
}

interface IGovernanceOrchestrator is IOrchestrator {
    function init(
        address ring,
        address admin,
        uint256 timelockDelay
    ) external returns (address governorAlpha, address timelock);
}
