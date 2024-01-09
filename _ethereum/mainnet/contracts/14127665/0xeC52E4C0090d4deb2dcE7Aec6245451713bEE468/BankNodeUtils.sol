// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PRBMathUD60x18.sol";

library BankNodeUtils {
    using PRBMathUD60x18 for uint256;

    function calculateSlashAmount(
        uint256 prevNodeBalance,
        uint256 nodeLoss,
        uint256 poolBalance
    ) internal pure returns (uint256) {
        uint256 slashRatio = (nodeLoss * PRBMathUD60x18.scale()).div(prevNodeBalance * PRBMathUD60x18.scale());
        return (poolBalance * slashRatio) / PRBMathUD60x18.scale();
    }

    function getMonthlyInterestPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) internal pure returns (uint256) {
        return
            (loanAmount *
                getPrincipleForMonth(interestAmount, numberOfPayments, currentMonth - 1).mul(interestAmount)) /
            PRBMathUD60x18.scale();
    }

    function getPrincipleForMonth(
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) internal pure returns (uint256) {
        uint256 ip1m = (PRBMathUD60x18.scale() + interestAmount).pow(currentMonth);
        uint256 right = getPaymentMultiplier(interestAmount, numberOfPayments).mul(
            (ip1m - PRBMathUD60x18.scale()).div(interestAmount)
        );
        return ip1m - right;
    }

    function getMonthlyPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments
    ) internal pure returns (uint256) {
        return (loanAmount * getPaymentMultiplier(interestAmount, numberOfPayments)) / PRBMathUD60x18.scale();
    }

    function getPaymentMultiplier(uint256 interestAmount, uint256 numberOfPayments) internal pure returns (uint256) {
        uint256 ip1n = (PRBMathUD60x18.scale() + interestAmount).pow(numberOfPayments);
        uint256 result = interestAmount.mul(ip1n).div((ip1n - PRBMathUD60x18.scale()));
        return result;
    }

    function getSwapExactTokensPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(tokenIn);
        path[1] = address(tokenOut);
        return path;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
