pragma solidity ^0.8.0;

/**
 * @dev Interface of the VeWom
 */
interface IWombatRouter {

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates the
     * maximum output token amount (accounting for fees and slippage).
     * @param tokenPath The token swap path
     * @param poolPath The token pool path
     * @param amountIn The from amount
     * @return amountOut The potential final amount user would receive
     */
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /// @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path
    /// @param tokenPath An array of token addresses. path.length must be >= 2.
    /// @param tokenPath The first element of the path is the input token, the last element is the output token.
    /// @param poolPath An array of pool addresses. The pools where the pathTokens are contained in order.
    /// @param amountIn the amount in
    /// @param minimumamountOut the minimum amount to get for user
    /// @param to the user to send the tokens to
    /// @param deadline the deadline to respect
    /// @return amountOut received by user
    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

}