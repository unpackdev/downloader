// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./SAave.sol";

interface ILendingPool {
    function getReserveData(address asset)
        external
        view
        returns (ReserveData memory);

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getReservesList() external view returns (address[] memory);
}
