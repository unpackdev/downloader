// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./Uniswap.sol";
import "./FuseMarginBase.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IUniswapV2Pair.sol";
import "./IFuseMarginController.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Clones.sol";

/// @author Ganesh Gautham Elango
/// @title FuseMargin contract that handles opening and closing of positions
contract FuseMarginV1 is Uniswap {
    using SafeERC20 for IERC20;

    /// @dev Position contract address
    address public immutable positionProxy;
    /// @dev FuseMarginController contract ERC721 interface
    IERC721 private immutable fuseMarginERC721;

    /// @param _connector ConnectorV1 address containing implementation logic
    /// @param _uniswapFactory Uniswap V2 Factory address
    /// @param _fuseMarginController FuseMarginController address
    /// @param _positionProxy Position address
    constructor(
        address _connector,
        address _uniswapFactory,
        address _fuseMarginController,
        address _positionProxy
    ) Uniswap(_connector, _uniswapFactory) FuseMarginBase(_fuseMarginController) {
        fuseMarginERC721 = IERC721(_fuseMarginController);
        positionProxy = _positionProxy;
    }

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
    ) external override returns (uint256) {
        IERC20(
            addresses[0] /* base */
        )
            .safeTransferFrom(msg.sender, address(this), providedAmount);
        address newPosition = Clones.clone(positionProxy);
        bytes memory data = abi.encode(Action.Open, msg.sender, newPosition, addresses, exchangeData);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
        return fuseMarginController.newPosition(msg.sender, newPosition);
    }

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
    ) external override {
        require(msg.sender == fuseMarginERC721.ownerOf(tokenId), "FuseMarginV1: Not owner of position");
        address positionAddress = fuseMarginController.closePosition(tokenId);
        bytes memory data = abi.encode(Action.Close, msg.sender, positionAddress, addresses, exchangeData);
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }
}
