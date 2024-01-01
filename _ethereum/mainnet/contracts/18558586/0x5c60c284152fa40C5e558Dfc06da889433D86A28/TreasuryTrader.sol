// SPDX-License-Identifier: GPL-3.0-only

/* ========== Requirements and Imports ========== 
================================================
*/

pragma solidity 0.8.9;

import {IUniswapV2Router02} from "IUniswapV2Router02.sol";
import {IWETH} from "IERCWETHInterfaces.sol";
import "Ownable.sol";
import "TransferHelper.sol";

/* ========== Contract ========== 
=================================
*/

contract TreasuryTrader is Ownable {
    // State Variables //

    //Assets swapped via 0x are left in the contract by default
    bool public sendToTreasury = false;

    address private _uniswapV2Router02Address =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant _AMPL = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;
    address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    //Address: Treasury
    address payable immutable TREASURY =
        payable(0xf950a86013bAA227009771181a885E369e158da3);

    address[] _pathUSDCToAMPL = new address[](3); //Uniswap V2 Path

    //Interfaces
    IERC20 private constant usdc = IERC20(_USDC);
    IWETH private constant weth = IWETH(_WETH);
    IERC20 private constant ampl = IERC20(_AMPL);

    IUniswapV2Router02 public uniswapV2Router =
        IUniswapV2Router02(_uniswapV2Router02Address);

    constructor() {
        _pathUSDCToAMPL[0] = address(usdc);
        _pathUSDCToAMPL[1] = address(weth);
        _pathUSDCToAMPL[2] = address(ampl);
    }

    /**
     * @notice Modifier to restrict certain functions to multisig only (treasury) calls
     * @dev Reverts if the caller is not the treasury.
     */
    modifier multiSigOnly() {
        require(msg.sender == TREASURY, "Multisig not caller");
        _;
    }

    //Transfer ERC20s from contract //
    /**
     * @notice Transfer deposited assets from contract
     * @dev Reverts if caller is not the treasury (multisig)
     */
    function transferAssetsFromTrader(
        IERC20 token,
        address to,
        uint256 amount
    ) public multiSigOnly {
        uint256 erc20balance = token.balanceOf(address(this));
        require(amount <= erc20balance, "balance too low to transfer token");
        token.transfer(to, amount);
    }

    //Uniswap v2 USDC --> AMPL Trade

    /**
     * @notice Use Uniswap V2 to swap USDC to AMPL.
     * @dev Swapped assets are deposited to Treasury by Uniswap. 
     * @dev Only owner can initiate swap. Owner does not have access to swapped assets.
     */

    function swapUSDCToAMPL(
        uint256 USDCAmountIn,
        uint256 AMPLAmountOut
    ) external onlyOwner returns (uint256 finalAmountOut) {
        // // Conduct v2 USDC --> AMPL Swap

        TransferHelper.safeApprove(
            address(usdc),
            address(uniswapV2Router),
            USDCAmountIn
        );

        uint[] memory usdcToAMPLHopAmountOut = uniswapV2Router
            .swapExactTokensForTokens(
                USDCAmountIn,
                AMPLAmountOut,
                _pathUSDCToAMPL,
                address(TREASURY),
                block.timestamp
            );

        finalAmountOut = usdcToAMPLHopAmountOut[2];
    }

    //Trade Other Assets Using 0x

    /**
     * @notice Swap any two assets using 0x.
     * @dev sendSwappedAssetToTreasury controls whether swapped asset remains in contract or is sent back to Treasury. 
     * @dev Only owner can initiate swap. Owner does not have access to swapped assets.
     */
    function swapAssets0x(
        bytes calldata swapCallData,
        address spender,
        address payable swapTarget,
        IERC20 sellToken,
        IERC20 buyToken,
        uint256 sellAmount,
        bool sendSwappedAssetToTreasury
    ) external payable onlyOwner {
        // Give `spender` an allowance to spend this contract's `sellToken`.
        // Note that for some tokens (e.g., USDT, KNC), any existing
        // allowance must be set to 0, before being able to update it.

        //Set send to Treasury status
        sendToTreasury = sendSwappedAssetToTreasury;

        if (address(sellToken) == _USDT) {
            //Reset approval to 0
            uint256 initialUSDTApprovalAmount = 0;

            TransferHelper.safeApprove(
                address(sellToken),
                address(spender),
                initialUSDTApprovalAmount
            );
        }

        //Approve WETH for any intermediate swaps
        TransferHelper.safeApprove(
            address(weth),
            address(spender),
            type(uint256).max
        );

        //Approve sell token for sell amount
        TransferHelper.safeApprove(
            address(sellToken),
            address(spender),
            sellAmount
        );

        // Call the encoded swap function at `swapTarget`,
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "Swap failed. Low balance / error.");

        //Send swapped assets to Treasury (if sendToTreasury = true)
        if (sendToTreasury == true) {
            //Transfer balance of buyToken back to Treasury
            buyToken.transfer(TREASURY, buyToken.balanceOf(address(this)));
        }
    }
}
