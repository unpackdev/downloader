// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISwapperV2Event {

    /// @dev                     TON -> WTON
    /// @param recipient         recipient Address
    /// @param amount            swapped ton amount
    event TonToWTON(address recipient, uint256 amount);

    /// @dev                     WTON -> TON
    /// @param recipient         recipient Address
    /// @param amount            swapped wton amount
    event WtonToTON(address recipient, uint256 amount);

    /// @dev                     exactInput token swap
    /// @param recipient         recipient Address
    /// @param inputToken        input Address
    /// @param outputToken       output Address
    /// @param amountIn          amountIn
    /// @param amountOut         amountOut
    event ExactInputEvent(
        address recipient,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev                     exactOutput token swap
    /// @param recipient         recipient Address
    /// @param inputToken        input Address
    /// @param outputToken       output Address
    /// @param amountOut         amountOut
    /// @param amountIn          amountIn
    /// @param refund            refund amount(amountInMaximum - amountIn)
    event ExactOutputEvent(
        address recipient,
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 refund 
    );
}