// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import "./IFuseMarginController.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMarginV1 Interface
interface IFuseMarginV1 {
    /// @dev FuseMarginController contract
    function fuseMarginController() external view returns (IFuseMarginController);

    /// @dev ConnectorV1 address containing implementation logic
    function connector() external view returns (address);

    /// @dev Opens a new position, provided an amount of base tokens, must approve base providedAmount before calling
    /// @param providedAmount Amount of base provided
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    /// @return tokenId of new position
    function openPosition(
        uint256 providedAmount,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external returns (uint256);

    /// @dev Closes an existing position, caller must own tokenId
    /// @param tokenId Position tokenId to close
    /// @param amount0Out Desired amount of token0 to borrow (0 if not being borrowed)
    /// @param amount1Out Desired amount of token1 to borrow (0 if not being borrowed)
    /// @param pair Uniswap V2 pair address to flash loan quote from
    /// @param addresses List of addresses to interact with
    ///                  [base, quote, pairToken, comptroller, cBase, cQuote, exchange]
    /// @param exchangeData Swap calldata
    function closePosition(
        uint256 tokenId,
        uint256 amount0Out,
        uint256 amount1Out,
        address pair,
        address[7] calldata addresses,
        bytes calldata exchangeData
    ) external;
}
