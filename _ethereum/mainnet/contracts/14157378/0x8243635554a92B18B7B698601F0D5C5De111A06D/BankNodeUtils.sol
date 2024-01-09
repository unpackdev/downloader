// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PRBMathUD60x18.sol";

library BankNodeUtils {
    using PRBMathUD60x18 for uint256;

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function calculateSlashAmount(
        uint256 prevNodeBalance,
        uint256 nodeLoss,
        uint256 poolBalance
    ) public pure returns (uint256) {
        uint256 slashRatio = (nodeLoss * PRBMathUD60x18.scale()).div(prevNodeBalance * PRBMathUD60x18.scale());
        return (poolBalance * slashRatio) / PRBMathUD60x18.scale();
    }

    function getMonthlyInterestPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) public pure returns (uint256) {
        return
            (loanAmount *
                getPrincipleForMonth(interestAmount, numberOfPayments, currentMonth - 1).mul(interestAmount)) /
            PRBMathUD60x18.scale();
    }

    function getPrincipleForMonth(
        uint256 interestAmount,
        uint256 numberOfPayments,
        uint256 currentMonth
    ) public pure returns (uint256) {
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
    ) public pure returns (uint256) {
        return (loanAmount * getPaymentMultiplier(interestAmount, numberOfPayments)) / PRBMathUD60x18.scale();
    }

    function getPaymentMultiplier(uint256 interestAmount, uint256 numberOfPayments) public pure returns (uint256) {
        uint256 ip1n = (PRBMathUD60x18.scale() + interestAmount).pow(numberOfPayments);
        uint256 result = interestAmount.mul(ip1n).div((ip1n - PRBMathUD60x18.scale()));
        return result;
    }

    function getSwapExactTokensPath(address tokenIn, address tokenOut) public pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = WETH;
        path[2] = address(tokenOut);
        return path;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }
}
