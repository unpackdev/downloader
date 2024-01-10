// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PRBMathUD60x18.sol";

/// @dev BNPL bank node mathematical calculation tools
/// @author BNPL
library BankNodeUtils {
    using PRBMathUD60x18 for uint256;

    /// @notice The wETH contract address (ERC20 tradable version of ETH)
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Calculate slash amount
    ///
    /// @param prevNodeBalance Previous bank node balance
    /// @param nodeLoss The loss amount of bank node
    /// @param poolBalance The staking pool balance of bank node
    /// @return slashAmount
    function calculateSlashAmount(
        uint256 prevNodeBalance,
        uint256 nodeLoss,
        uint256 poolBalance
    ) internal pure returns (uint256) {
        uint256 slashRatio = (nodeLoss * PRBMathUD60x18.scale()).div(prevNodeBalance * PRBMathUD60x18.scale());
        return (poolBalance * slashRatio) / PRBMathUD60x18.scale();
    }

    /// @notice Calculate monthly interest payment
    ///
    /// @param loanAmount Amount of loan
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @param currentMonth Number of payments made
    /// @return monthlyInterestPayment
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

    /// @notice Calculate principle for month
    ///
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @param currentMonth Number of payments made
    /// @return principleForMonth
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

    /// @notice Calculate monthly payment
    ///
    /// @param loanAmount Amount of loan
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @return monthlyPayment
    function getMonthlyPayment(
        uint256 loanAmount,
        uint256 interestAmount,
        uint256 numberOfPayments
    ) internal pure returns (uint256) {
        return (loanAmount * getPaymentMultiplier(interestAmount, numberOfPayments)) / PRBMathUD60x18.scale();
    }

    /// @notice Calculate payment multiplier
    ///
    /// @param interestAmount Interest rate per payment
    /// @param numberOfPayments The number of payments
    /// @return paymentMultiplier
    function getPaymentMultiplier(uint256 interestAmount, uint256 numberOfPayments) internal pure returns (uint256) {
        uint256 ip1n = (PRBMathUD60x18.scale() + interestAmount).pow(numberOfPayments);
        uint256 result = interestAmount.mul(ip1n).div((ip1n - PRBMathUD60x18.scale()));
        return result;
    }

    /// @dev Sushiswap exact tokens path (join wETH in the middle)
    ///
    /// @param tokenIn input token address
    /// @param tokenOut output token address
    /// @return swapExactTokensPath
    function getSwapExactTokensPath(address tokenIn, address tokenOut) internal pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = address(tokenIn);
        path[1] = WETH;
        path[2] = address(tokenOut);
        return path;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
