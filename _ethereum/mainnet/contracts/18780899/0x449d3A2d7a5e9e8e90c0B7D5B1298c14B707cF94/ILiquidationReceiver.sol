// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ILiquidationReceiver {
    error InvalidOperationExecution();

    event OperationExecuteForCollateral(
        address liquidator,
        address user,
        bytes32 ccy,
        uint256 receivedAmount
    );
    event OperationExecuteForDebt(
        address liquidator,
        address user,
        bytes32 collateralCcy,
        uint256 receivedCollateralAmount,
        bytes32 debtCcy,
        uint256 debtMaturity,
        uint256 receivedDebtAmount
    );

    function executeOperationForCollateral(
        address liquidator,
        address user,
        bytes32 ccy,
        uint256 receivedAmount
    ) external returns (bool);

    function executeOperationForDebt(
        address liquidator,
        address user,
        bytes32 collateralCcy,
        uint256 receivedCollateralAmount,
        bytes32 debtCcy,
        uint256 debtMaturity,
        uint256 receivedDebtAmount
    ) external returns (bool);
}
