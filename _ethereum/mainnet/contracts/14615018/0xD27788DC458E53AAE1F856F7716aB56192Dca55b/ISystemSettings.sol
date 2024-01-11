pragma solidity 0.7.6;

interface ISystemSettings {
    struct PoolSetting {
        address owner;
        uint256 marginRatio;
        uint256 closingFee;
        uint256 liqFeeBase;
        uint256 liqFeeMax;
        uint256 liqFeeCoefficient;
        uint256 liqLsRequire;
        uint256 rebaseCoefficient;
        uint256 imbalanceThreshold;
        uint256 priceDeviationCoefficient;
        uint256 minHoldingPeriod;
        uint256 debtStart;
        uint256 debtAll;
        uint256 minDebtRepay;
        uint256 maxDebtRepay;
        uint256 interestRate;
        uint256 liquidityCoefficient;
        bool deviation;
    }

    function official() external view returns (address);

    function deployer02() external view returns (address);

    function leverages(uint32) external view returns (bool);

    function protocolFee() external view returns (uint256);

    function liqProtocolFee() external view returns (uint256);

    function marginRatio() external view returns (uint256);

    function closingFee() external view returns (uint256);

    function liqFeeBase() external view returns (uint256);

    function liqFeeMax() external view returns (uint256);

    function liqFeeCoefficient() external view returns (uint256);

    function liqLsRequire() external view returns (uint256);

    function rebaseCoefficient() external view returns (uint256);

    function imbalanceThreshold() external view returns (uint256);

    function priceDeviationCoefficient() external view returns (uint256);

    function minHoldingPeriod() external view returns (uint256);

    function debtStart() external view returns (uint256);

    function debtAll() external view returns (uint256);

    function minDebtRepay() external view returns (uint256);

    function maxDebtRepay() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function liquidityCoefficient() external view returns (uint256);

    function deviation() external view returns (bool);

    function checkOpenPosition(uint16 level) external view;

    function requireSystemActive() external view;

    function requireSystemSuspend() external view;

    function resumeSystem() external;

    function suspendSystem() external;

    function mulClosingFee(uint256 value) external view returns (uint256);

    function mulLiquidationFee(uint256 margin, uint256 deltaBlock) external view returns (uint256);

    function mulMarginRatio(uint256 margin) external view returns (uint256);

    function mulProtocolFee(uint256 amount) external view returns (uint256);

    function mulLiqProtocolFee(uint256 amount) external view returns (uint256);

    function meetImbalanceThreshold(
        uint256 nakedPosition,
        uint256 liquidityPool
    ) external view returns (bool);

    function mulImbalanceThreshold(uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calDeviation(uint256 nakedPosition, uint256 liquidityPool)
        external
        view
        returns (uint256);

    function calRebaseDelta(
        uint256 rebaseSizeXBlockDelta,
        uint256 imbalanceSize
    ) external view returns (uint256);

    function calDebtRepay(
        uint256 lsPnl,
        uint256 totalDebt,
        uint256 totalLiquidity
    ) external view returns (uint256);

    function calDebtIssue(
        uint256 tdPnl,
        uint256 lsAvgPrice,
        uint256 lsPrice
    ) external view returns (uint256);

    function mulInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function divInterestFromDebt(
        uint256 amount
    ) external view returns (uint256);

    function mulLiquidityCoefficient(
        uint256 nakedPositions
    ) external view returns (uint256);

    enum systemParam {
        MarginRatio,
        ProtocolFee,
        LiqProtocolFee,
        ClosingFee,
        LiqFeeBase,
        LiqFeeMax,
        LiqFeeCoefficient,
        LiqLsRequire,
        RebaseCoefficient,
        ImbalanceThreshold,
        PriceDeviationCoefficient,
        MinHoldingPeriod,
        DebtStart,
        DebtAll,
        MinDebtRepay,
        MaxDebtRepay,
        InterestRate,
        LiquidityCoefficient,
        Other
    }

    event AddLeverage(uint32 leverage);
    event DeleteLeverage(uint32 leverage);

    event SetSystemParam(systemParam param, uint256 value);
    event SetDeviation(bool deviation);

    event SetPoolOwner(address pool, address owner);
    event SetPoolParam(address pool, systemParam param, uint256 value);
    event SetPoolDeviation(address pool, bool deviation);

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}
