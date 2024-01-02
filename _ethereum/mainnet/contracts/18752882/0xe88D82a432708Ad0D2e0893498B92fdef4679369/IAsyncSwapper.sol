// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct SwapParams {
    /// @dev The address of the token to be sold.
    address sellTokenAddress;
    /// @dev The amount of tokens to be sold.
    uint256 sellAmount;
    /// @dev The address of the token to be bought.
    address buyTokenAddress;
    /// @dev The expected minimum amount of tokens to be bought.
    uint256 buyAmount;
    /// @dev Data payload generated off-chain.
    bytes data;
}

interface IAsyncSwapper {
    error SwapFailed();
    error InsufficientBuyAmountReceived(address buyTokenAddress, uint256 buyTokenAmountReceived, uint256 buyAmount);

    event Swapped(
        address indexed sellTokenAddress,
        address indexed buyTokenAddress,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 buyTokenAmountReceived
    );

    /**
     * @notice Swaps sellToken for buyToken
     * @dev Only payable so it can be called from bridge fn
     * @param swapParams Encoded swap data
     * @return buyTokenAmountReceived The amount of buyToken received from the swap
     */
    function swap(SwapParams memory swapParams) external payable returns (uint256 buyTokenAmountReceived);
}
