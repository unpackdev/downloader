// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./CErc20Interface.sol";
import "./ComptrollerInterface.sol";

/// @author Ganesh Gautham Elango
/// @title Connector contract containing the position implementation logic
contract ConnectorV1 {
    using SafeERC20 for IERC20;

    /// @dev Transfer ETH balance
    /// @param to Address to send to
    /// @param amount Amount of ETH to send
    function transferETH(address to, uint256 amount) external {
        payable(to).transfer(amount);
    }

    /// @dev Transfers token balance
    /// @param token Token address
    /// @param to Transfer to address
    /// @param amount Amount to transfer
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @dev Deposits token into pool, must have transferred the token to this contract before calling
    /// @param base Token to deposit
    /// @param cBase Equivalent cToken address
    /// @param depositAmount Amount to deposit
    function mint(
        address base,
        address cBase,
        uint256 depositAmount
    ) external {
        IERC20(base).safeTransferFrom(msg.sender, address(this), depositAmount);
        IERC20(base).safeApprove(cBase, depositAmount);
        require(CErc20Interface(cBase).mint(depositAmount) == 0, "Position: mint in mint failed");
    }

    /// @dev Enable tokens as collateral
    /// @param comptroller Address of Comptroller for the pool
    /// @param cTokens List of cToken addresses to enable as collateral
    function enterMarkets(address comptroller, address[] calldata cTokens) external {
        uint256[] memory errors = ComptrollerInterface(comptroller).enterMarkets(cTokens);
        for (uint256 i = 0; i < errors.length; i++) {
            require(errors[i] == 0, "Position: enterMarkets in enterMarkets failed");
        }
    }

    /// @dev Borrow a token, must have first called enterMarkets for the base collateral
    /// @param quote Token to borrow
    /// @param cQuote Equivalent cToken
    /// @param transferTo Address to transfer borrowed tokens to
    /// @param borrowAmount Amount to borrow
    function borrow(
        address quote,
        address cQuote,
        address transferTo,
        uint256 borrowAmount
    ) external {
        require(CErc20Interface(cQuote).borrow(borrowAmount) == 0, "Position: borrow in borrow failed");
        IERC20(quote).safeTransfer(transferTo, borrowAmount);
    }

    /// @dev Repay borrowed token, must have transferred the token to this contract before calling
    /// @param quote Token to repay
    /// @param cQuote Equivalent cToken
    /// @param repayAmount Amount to repay
    function repayBorrow(
        address quote,
        address cQuote,
        uint256 repayAmount
    ) external {
        IERC20(quote).safeTransferFrom(msg.sender, address(this), repayAmount);
        IERC20(quote).safeApprove(cQuote, repayAmount);
        require(CErc20Interface(cQuote).repayBorrow(repayAmount) == 0, "Position: repayBorrow in repayBorrow failed");
    }

    /// @dev Withdraw token from pool, given cToken amount
    /// @param base Token to withdraw
    /// @param cBase Equivalent cToken
    /// @param transferTo Address to transfer borrowed tokens to
    /// @param redeemTokens Amount of cToken to withdraw
    function redeem(
        address base,
        address cBase,
        address transferTo,
        uint256 redeemTokens
    ) external {
        require(
            CErc20Interface(cBase).redeem(redeemTokens) == 0,
            "Position: redeemUnderlying in redeemUnderlying failed"
        );
        IERC20(base).safeTransfer(transferTo, IERC20(base).balanceOf(address(this)));
    }

    /// @dev Withdraw token from pool, given token amount
    /// @param base Token to withdraw
    /// @param cBase Equivalent cToken
    /// @param transferTo Address to transfer borrowed tokens to
    /// @param redeemAmount Amount of token to withdraw
    function redeemUnderlying(
        address base,
        address cBase,
        address transferTo,
        uint256 redeemAmount
    ) external {
        require(
            CErc20Interface(cBase).redeemUnderlying(redeemAmount) == 0,
            "Position: redeemUnderlying in redeemUnderlying failed"
        );
        IERC20(base).safeTransfer(transferTo, redeemAmount);
    }

    /// @dev Enter market and deposit
    /// @param comptroller Address of Comptroller for the pool
    /// @param base Token to deposit
    /// @param cBase Equivalent cToken address
    /// @param cToken List of equivalent cToken address to enable as collateral
    /// @param depositAmount Amount to deposit
    function enterMarketAndMint(
        address comptroller,
        address base,
        address cBase,
        address[] calldata cToken,
        uint256 depositAmount
    ) external {
        uint256[] memory errors = ComptrollerInterface(comptroller).enterMarkets(cToken);
        require(errors[0] == 0, "Position: enterMarkets in enterMarkets failed");
        IERC20(base).safeTransferFrom(msg.sender, address(this), depositAmount);
        IERC20(base).safeApprove(cBase, depositAmount);
        require(CErc20Interface(cBase).mint(depositAmount) == 0, "Position: mint in mint failed");
    }

    /// @dev Deposits a token, enables it as collateral and borrows a token,
    ///      must have transferred the deposit token to this contract before calling
    /// @param comptroller Address of Comptroller for the pool
    /// @param base Token to deposit
    /// @param cBase Equivalent cToken
    /// @param quote Token to borrow
    /// @param cQuote Equivalent cToken
    /// @param depositAmount Amount of base to deposit
    /// @param borrowAmount Amount of quote to borrow
    function mintAndBorrow(
        address comptroller,
        address base,
        address cBase,
        address quote,
        address cQuote,
        uint256 depositAmount,
        uint256 borrowAmount
    ) external {
        IERC20(base).safeApprove(cBase, depositAmount);
        require(CErc20Interface(cBase).mint(depositAmount) == 0, "Position: mint in mintAndBorrow failed");
        address[] memory cTokens = new address[](1);
        cTokens[0] = cBase;
        uint256[] memory errors = ComptrollerInterface(comptroller).enterMarkets(cTokens);
        require(errors[0] == 0, "Position: enterMarkets in mintAndBorrow failed");
        require(CErc20Interface(cQuote).borrow(borrowAmount) == 0, "Position: borrow in mintAndBorrow failed");
        IERC20(quote).safeTransfer(msg.sender, borrowAmount);
    }

    /// @dev Repay quote and redeem base, must have transferred the repay token to this contract before calling
    /// @param base Token to redeem
    /// @param cBase Equivalent cToken
    /// @param quote Token to repay
    /// @param cQuote Equivalent cToken
    /// @param redeemTokens Amount of cTokens to redeem
    /// @param repayAmount Amount to repay
    function repayAndRedeem(
        address base,
        address cBase,
        address quote,
        address cQuote,
        uint256 redeemTokens,
        uint256 repayAmount
    ) external {
        IERC20(quote).safeApprove(cQuote, repayAmount);
        require(
            CErc20Interface(cQuote).repayBorrow(repayAmount) == 0,
            "Position: repayBorrow in repayAndRedeem failed"
        );
        require(CErc20Interface(cBase).redeem(redeemTokens) == 0, "Position: redeem in repayAndRedeem failed");
        IERC20(base).safeTransfer(msg.sender, IERC20(base).balanceOf(address(this)));
    }
}
