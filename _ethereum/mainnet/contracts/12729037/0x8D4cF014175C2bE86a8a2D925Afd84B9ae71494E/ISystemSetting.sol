// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface ISystemSetting {
    // maxInitialLiquidityFunding
    function maxInitialLiquidityFunding() external view returns (uint256);

    // constantMarginRatio
    function constantMarginRatio() external view returns (uint256);

    // leverageExist
    function leverageExist(uint32 leverage_) external view returns (bool);

    // minInitialMargin
    function minInitialMargin() external view returns (uint256);

    // minAddDeposit
    function minAddDeposit() external view returns (uint256);

    // minHoldingPeriod
    function minHoldingPeriod() external view returns (uint);

    // marginRatio
    function marginRatio() external view returns (uint256);

    // positionClosingFee
    function positionClosingFee() external view returns (uint256);

    // liquidationFee
    function liquidationFee() external view returns (uint256);

    // rebaseInterval
    function rebaseInterval() external view returns (uint);

    // rebaseRate
    function rebaseRate() external view returns (uint);

    // imbalanceThreshold
    function imbalanceThreshold() external view returns (uint);

    // minFundTokenRequired
    function minFundTokenRequired() external view returns (uint);

    function checkOpenPosition(uint position, uint16 level) external view;
    function checkAddDeposit(uint margin) external view;

    function requireSystemActive() external;
    function resumeSystem() external;
    function suspendSystem() external;

    event Suspend(address indexed sender);
    event Resume(address indexed sender);
}
