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
///@notice This contract removes liquidity from Pickle Jars to ETH or ERC20 Tokens.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
import "./ZapOutBaseV1.sol";

interface IPickleJar {
    function token() external view returns (address);

    function withdraw(uint256 _shares) external;

    function getRatio() external view returns (uint256);
}

contract Pickle_ZapOut_V1 is ZapOutBaseV1 {
    // calldata only accepted for approved zap contracts
    mapping(address => bool) public approvedTargets;

    event Zapout(
        address _toWhomToIssue,
        address _fromPJarAddress,
        address _toTokenAddress,
        uint256 _tokensRecieved
    );

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    /**
    @notice Zap out in to a single token or ETH
    @param fromJar Pickle Jar from which to remove liquidity
    @param amountIn Quantity of Jar tokens to remove
    @param toToken Address of desired token
    @param minToTokens Minimum quantity of tokens to receive, reverts otherwise
    @param swapTarget Execution targets for swap or Zap
    @param swapData DEX or Zap data
    @param affiliate Affiliate address
    @return Quantity of tokens or ETH received
    */
    function ZapOut(
        address fromJar,
        uint256 amountIn,
        address toToken,
        uint256 minToTokens,
        address swapTarget,
        bytes memory swapData,
        address affiliate
    ) public stopInEmergency returns (uint256 tokensReceived) {
        require(
            approvedTargets[swapTarget] || swapTarget == address(0),
            "Target not Authorized"
        );

        IERC20(fromJar).safeTransferFrom(msg.sender, address(this), amountIn);

        // withdraw underlying token from jar
        address underlyingToken = IPickleJar(fromJar).token();
        uint256 underlyingTokenReceived =
            _jarWithdraw(fromJar, amountIn, underlyingToken);

        // swap to toToken
        uint256 toTokenAmt =
            _fillQuote(
                underlyingToken,
                toToken,
                underlyingTokenReceived,
                swapTarget,
                swapData
            );
        require(toTokenAmt >= minToTokens, "Err: High Slippage");

        uint256 totalGoodwillPortion =
            _subtractGoodwill(toToken, toTokenAmt, affiliate, true);
        tokensReceived = toTokenAmt.sub(totalGoodwillPortion);

        // send toTokens
        if (toToken == address(0)) {
            Address.sendValue(msg.sender, tokensReceived);
        } else {
            IERC20(toToken).safeTransfer(msg.sender, tokensReceived);
        }
    }

    function _jarWithdraw(
        address fromJar,
        uint256 amount,
        address underlyingToken
    ) internal returns (uint256 underlyingReceived) {
        uint256 iniUnderlyingBal = _getBalance(underlyingToken);

        IPickleJar(fromJar).withdraw(amount);

        underlyingReceived = _getBalance(underlyingToken).sub(iniUnderlyingBal);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address _swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;

        if (_fromTokenAddress == toToken) {
            return _amount;
        }

        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            _approveToken(_fromTokenAddress, _swapTarget, _amount);
        }

        uint256 iniBal = _getBalance(toToken);

        (bool success, ) = _swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");

        uint256 finalBal = _getBalance(toToken);

        require(finalBal > 0, "ERR: Swapped to wrong token");

        amtBought = finalBal.sub(iniBal);
    }

    /**
    @notice Utility function to determine the quantity of underlying tokens removed from jar
    @param fromJar Pickle Jar from which to remove liquidity
    @param liquidity Quantity of Jar tokens to remove
    @return Quantity of underlying LP or token removed
    */
    function removeLiquidityReturn(IPickleJar fromJar, uint256 liquidity)
        external
        view
        returns (uint256)
    {
        return (liquidity.mul(fromJar.getRatio())).div(1e18);
    }

    function setApprovedTargets(
        address[] calldata targets,
        bool[] calldata isApproved
    ) external onlyOwner {
        require(targets.length == isApproved.length, "Invalid Input length");

        for (uint256 i = 0; i < targets.length; i++) {
            approvedTargets[targets[i]] = isApproved[i];
        }
    }
}
