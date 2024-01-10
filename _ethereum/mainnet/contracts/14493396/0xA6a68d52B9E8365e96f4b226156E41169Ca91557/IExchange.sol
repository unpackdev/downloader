//SPDX-License-Identifier: BUSL
pragma solidity 0.8.10;

import "./IERC20.sol";

interface IExchange {
    /// @dev Calculation of the number of tokens that you need to spend to get _ethAmount
    /// @param _token - The address of the token that we exchange for ETH.
    /// @param _ethAmount - The amount of ETH to be received.
    /// @return The number of tokens you need to get ETH.
    function getEstimatedTokensForETH(IERC20 _token, uint256 _ethAmount) external returns (uint256);

    /// @dev Exchange tokens for ETH
    /// @param _token - The address of the token that we exchange for ETH.
    /// @param _receiveEthAmount - The exact amount of ETH to be received.
    /// @param _tokensMaxSpendAmount - The maximum number of tokens allowed to spend.
    /// @param _ethReceiver - The wallet address to send ETH to after the exchange.
    /// @param _tokensReceiver - Wallet address, to whom to send the remaining unused tokens from the exchange.
    /// @return Number of tokens spent.
    function swapTokensToETH(IERC20 _token, uint256 _receiveEthAmount, uint256 _tokensMaxSpendAmount, address _ethReceiver, address _tokensReceiver) external returns (uint256);
}
