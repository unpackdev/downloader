// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;
pragma abicoder v2;

import "./Utils.sol";
import "./ISmardexRouter.sol";

contract SmarDex {
    struct SmarDexData {
        address[] path;
        address receiver;
    }

    function swapOnSmarDex(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        SmarDexData memory data = abi.decode(payload, (SmarDexData));

        if (address(fromToken) == Utils.ethAddress()) {
            ISmardexRouter(targetExchange).swapExactETHForTokens{ value: fromAmount }(
                1,
                data.path,
                data.receiver,
                block.timestamp
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            Utils.approve(address(targetExchange), address(fromToken), fromAmount);
            ISmardexRouter(targetExchange).swapExactTokensForETH(
                fromAmount,
                1,
                data.path,
                data.receiver,
                block.timestamp
            );
        } else {
            Utils.approve(address(targetExchange), address(fromToken), fromAmount);
            ISmardexRouter(targetExchange).swapExactTokensForTokens(
                fromAmount,
                1,
                data.path,
                data.receiver,
                block.timestamp
            );
        }
    }

    function buyOnSmarDex(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 maxFromAmount,
        uint256 toAmount,
        address targetExchange,
        bytes calldata payload
    ) internal {
        SmarDexData memory data = abi.decode(payload, (SmarDexData));

        if (address(fromToken) == Utils.ethAddress()) {
            ISmardexRouter(targetExchange).swapETHForExactTokens{ value: maxFromAmount }(
                toAmount,
                data.path,
                data.receiver,
                block.timestamp
            );
        } else if (address(toToken) == Utils.ethAddress()) {
            Utils.approve(address(targetExchange), address(fromToken), maxFromAmount);
            ISmardexRouter(targetExchange).swapTokensForExactETH(
                toAmount,
                maxFromAmount,
                data.path,
                data.receiver,
                block.timestamp
            );
        } else {
            Utils.approve(address(targetExchange), address(fromToken), maxFromAmount);
            ISmardexRouter(targetExchange).swapTokensForExactTokens(
                toAmount,
                maxFromAmount,
                data.path,
                data.receiver,
                block.timestamp
            );
        }
    }
}
