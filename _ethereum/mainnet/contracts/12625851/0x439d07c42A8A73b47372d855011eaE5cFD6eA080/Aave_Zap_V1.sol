// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract deposits and withdraws assets to/from Aave
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;
import "./ZapInBaseV3_1.sol";
import "./ZapOutBaseV3_1.sol";
import "./AaveInterface.sol";

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

contract Aave_Zap_V1 is ZapInBaseV3_1, ZapOutBaseV3_1 {
    using SafeERC20 for IERC20;

    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    address private constant wethTokenAddress =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    //@dev targets must be Zaps (not tokens!!!)
    constructor(
        address[] memory targets,
        uint256 _goodwill,
        uint256 _affiliateSplit
    ) ZapBaseV2_1(_goodwill, _affiliateSplit) {
        approvedTargets[0xDef1C0ded9bec7F1a1670819833240f027b25EfF] = true;
        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = true;
        }
    }

    event zapIn(address sender, address token, uint256 tokensRec);
    event zapOut(address sender, address token, uint256 tokensRec);

    /**
    @notice This function deposits assets into aave with ETH or ERC20 tokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param aToken Address of the aToken
    @param minATokens The minimum acceptable quantity aTokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data. Must swap to aToken underlying address
    @param affiliate Affiliate address
    @return aTokensRec Quantity of aTokens received
     */
    function ZapIn(
        address fromToken,
        uint256 amountIn,
        address aToken,
        uint256 minATokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external payable stopInEmergency returns (uint256 aTokensRec) {
        uint256 toInvest = _pullTokens(fromToken, amountIn, affiliate, true);

        address toToken = getUnderlyingToken(aToken);

        uint256 tokensBought =
            _fillQuote(fromToken, toToken, toInvest, swapTarget, swapData);

        (aTokensRec) = enterAave(aToken, tokensBought);
        require(aTokensRec > minATokens, "High Slippage");

        IERC20(aToken).safeTransfer(msg.sender, aTokensRec);

        emit zapIn(msg.sender, aToken, aTokensRec);
    }

    function enterAave(address aToken, uint256 underlyingAmount)
        internal
        returns (uint256 aTokensRec)
    {
        ILendingPool lendingPool = getLendingPool(aToken);

        address underlyingToken = getUnderlyingToken(aToken);

        uint256 initialBalance = _getBalance(aToken);

        _approveToken(underlyingToken, address(lendingPool), underlyingAmount);

        lendingPool.deposit(
            underlyingToken,
            underlyingAmount,
            address(this),
            0
        );

        aTokensRec = _getBalance(aToken) - initialBalance;
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or ETH with permit
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param permitSig Signature for permit
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOutWithPermit(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        bytes calldata permitSig,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) external stopInEmergency returns (uint256) {
        _permit(fromToken, permitAllowance, permitSig);

        return (
            ZapOut(
                fromToken,
                amountIn,
                toToken,
                minToTokens,
                swapTarget,
                swapData,
                affiliate
            )
        );
    }

    function _permit(
        address aToken,
        uint256 amountIn,
        bytes memory permitSig
    ) internal {
        require(permitSig.length == 65, "Invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(permitSig, 32))
            s := mload(add(permitSig, 64))
            v := byte(0, mload(add(permitSig, 96)))
        }
        IAToken(aToken).permit(
            msg.sender,
            address(this),
            amountIn,
            deadline,
            v,
            r,
            s
        );
    }

    /**
    @notice This function withdraws assets from aave, receiving tokens or ETH
    @param fromToken The aToken being withdrawn
    @param amountIn The quantity of fromToken to withdraw
    @param toToken Address of the token to receive (0 address if ETH)
    @param minToTokens The minimum acceptable quantity tokens to receive. Reverts otherwise
    @param swapTarget Excecution target for the swap or zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return tokensRec Quantity of aTokens received
     */
    function ZapOut(
        address fromToken,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensRec) {
        amountIn = _pullTokens(fromToken, amountIn);

        uint256 underlyingRec = exitAave(fromToken, amountIn);

        address underlyingToken = getUnderlyingToken(fromToken);

        tokensRec = _fillQuote(
            underlyingToken,
            toToken,
            underlyingRec,
            swapTarget,
            swapData
        );

        require(tokensRec >= minToTokens, "High Slippage");

        uint256 totalGoodwillPortion;

        if (toToken == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                tokensRec,
                affiliate,
                true
            );

            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                toToken,
                tokensRec,
                affiliate,
                true
            );

            IERC20(toToken).safeTransfer(
                msg.sender,
                tokensRec - totalGoodwillPortion
            );
        }

        tokensRec = tokensRec - totalGoodwillPortion;

        emit zapOut(msg.sender, toToken, tokensRec);
    }

    function exitAave(address aToken, uint256 aTokenAmount)
        internal
        returns (uint256 tokensRec)
    {
        address underlyingToken = getUnderlyingToken(aToken);

        ILendingPool lendingPool = getLendingPool(aToken);

        tokensRec = lendingPool.withdraw(
            underlyingToken,
            aTokenAmount,
            address(this)
        );
    }

    function _fillQuote(
        address fromToken,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapData
    ) internal returns (uint256 amountBought) {
        if (fromToken == toToken) {
            return _amount;
        }

        if (fromToken == address(0) && toToken == wethTokenAddress) {
            IWETH(wethTokenAddress).deposit{ value: _amount }();
            return _amount;
        }

        if (fromToken == wethTokenAddress && toToken == address(0)) {
            IWETH(wethTokenAddress).withdraw(_amount);
            return _amount;
        }

        uint256 valueToSend;
        if (fromToken == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(fromToken, swapTarget);
        }

        uint256 initialBalance = _getBalance(toToken);

        require(approvedTargets[swapTarget], "Target not Authorized");
        (bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
        require(success, "Error Swapping Tokens");

        amountBought = _getBalance(toToken) - initialBalance;

        require(amountBought > 0, "Swapped To Invalid Intermediate");
    }

    function getUnderlyingToken(address aToken) public returns (address) {
        return IAToken(aToken).UNDERLYING_ASSET_ADDRESS();
    }

    function getLendingPool(address aToken) internal returns (ILendingPool) {
        return ILendingPool(IAToken(aToken).POOL());
    }
}
