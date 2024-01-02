// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuantumCollateralManagement {
    mapping(address => uint256) public collateralBalances;

    event CollateralDeposited(address indexed borrower, uint256 amount);
    event CollateralWithdrawn(address indexed borrower, uint256 amount);

    function depositCollateral(address borrower, uint256 amount) external {
        collateralBalances[borrower] += amount;
        emit CollateralDeposited(borrower, amount);
    }

    function withdrawCollateral(address borrower, uint256 amount) external {
        require(collateralBalances[borrower] >= amount, "QuantumCollateralManagement: Insufficient collateral balance");
        collateralBalances[borrower] -= amount;
        emit CollateralWithdrawn(borrower, amount);
    }

    function getCollateralBalance(address borrower) external view returns (uint256) {
        return collateralBalances[borrower];
    }

    function isCollateralSufficient(address borrower, uint256 loanAmount, uint256 threshold) external view returns (bool) {
        uint256 collateralAmount = collateralBalances[borrower];
        return collateralAmount >= loanAmount * threshold / 1e18;
    }
}