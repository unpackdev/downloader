// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;
pragma abicoder v2;

struct Position {
    uint share;                 // decimals 18
    uint openPositionPrice;     // decimals 18
    uint leveragedPosition;     // decimals 6
    uint margin;                // decimals 6
    uint openRebaseLeft;        // decimals 18
    address account;
    uint32 currencyKeyIdx;
    uint8 direction;
}

interface IDepot {
    function initialFundingCompleted() external view returns (bool);
    function liquidityPool() external view returns (uint);
    function totalLeveragedPositions() external view returns (uint);
    function totalValue() external view returns (uint);

    function position(uint32 index) external view returns (
        address account,
        uint share,
        uint leveragedPosition,
        uint openPositionPrice,
        uint32 currencyKeyIdx,
        uint8 direction,
        uint margin,
        uint openRebaseLeft);

    function netValue(uint8 direction) external view returns (uint);
    function calMarginLoss(uint leveragedPosition, uint share, uint8 direction) external view returns (uint);
    function calNetProfit(uint32 currencyKeyIdx,
        uint leveragedPosition,
        uint openPositionPrice,
        uint8 direction) external view returns (bool, uint);

    function completeInitialFunding() external;

    function updateSubTotalState(bool isLong, uint liquidity, uint detaMargin,
        uint detaLeveraged, uint detaShare, uint rebaseLeft) external;
    function getTotalPositionState() external view returns (uint, uint, uint, uint);

    function newPosition(
        address account,
        uint openPositionPrice,
        uint margin,
        uint32 currencyKeyIdx,
        uint16 level,
        uint8 direction) external returns (uint32);

    function addDeposit(
        address account,
        uint32 positionId,
        uint margin) external;

    function liquidate(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint fee,
        uint value,
        uint marginLoss,
        uint liqReward,
        address liquidator) external;

    function bankruptedLiquidate(
        Position memory position,
        uint32 positionId,
        uint liquidateFee,
        uint marginLoss,
        address liquidator) external;

    function closePosition(
        Position memory position,
        uint32 positionId,
        bool isProfit,
        uint value,
        uint marginLoss,
        uint fee) external;

    function addLiquidity(address account, uint value) external;
    function withdrawLiquidity(address account, uint value) external;
}
