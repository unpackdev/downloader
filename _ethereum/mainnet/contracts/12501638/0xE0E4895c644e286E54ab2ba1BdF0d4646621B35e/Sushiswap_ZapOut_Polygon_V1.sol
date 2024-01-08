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
// Visit <https://www.gnu.org/licenses/>for a copy of the GNU Affero General Public License

///@author Zapper
///@notice this contract implements one click removal of liquidity from Sushiswap pools, receiving ETH, ERC tokens or both.
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;
import "./ZapOutBaseV2.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IWETH {
    function withdraw(uint256 wad) external;
}

contract Sushiswap_ZapOut_Polygon_V1 is ZapOutBaseV2_1 {
    uint256 private constant deadline =
        0xf000000000000000000000000000000000000000000000000000000000000000;

    // sushiSwap
    IUniswapV2Router02 private constant sushiSwapRouter =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address private constant wmaticTokenAddress =
        address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
        public
        ZapBaseV1(_goodwill, _affiliateSplit)
    {}

    event zapOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
    @notice Zap out in both tokens with permit
    @param fromSushiPool Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param affiliate Affiliate address to share fees
    @return  amountA, amountB - Quantity of tokens received 
    */
    function ZapOut2PairToken(
        address fromSushiPool,
        uint256 incomingLP,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);

        require(
            address(pair) != address(0),
            "Error: Invalid Sushipool Address"
        );

        //get reserves
        address token0 = pair.token0();
        address token1 = pair.token1();

        incomingLP = _pullTokens(
            fromSushiPool,
            incomingLP,
            shouldSellEntireBalance
        );

        _approveToken(fromSushiPool, address(sushiSwapRouter), incomingLP);

        if (token0 == wmaticTokenAddress || token1 == wmaticTokenAddress) {
            address _token = token0 == wmaticTokenAddress ? token1 : token0;
            (amountA, amountB) = sushiSwapRouter.removeLiquidityETH(
                _token,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenGoodwill =
                _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill =
                _subtractGoodwill(ETHAddress, amountB, affiliate, true);

            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA.sub(tokenGoodwill));
            Address.sendValue(msg.sender, amountB.sub(ethGoodwill));
        } else {
            (amountA, amountB) = sushiSwapRouter.removeLiquidity(
                token0,
                token1,
                incomingLP,
                1,
                1,
                address(this),
                deadline
            );

            // subtract goodwill
            uint256 tokenAGoodwill =
                _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill =
                _subtractGoodwill(token1, amountB, affiliate, true);

            // send tokens
            IERC20(token0).safeTransfer(
                msg.sender,
                amountA.sub(tokenAGoodwill)
            );
            IERC20(token1).safeTransfer(
                msg.sender,
                amountB.sub(tokenBGoodwill)
            );
        }
        emit zapOut(msg.sender, fromSushiPool, token0, amountA);
        emit zapOut(msg.sender, fromSushiPool, token1, amountB);
    }

    /**
    @notice Zap out in a single token
    @param toToken Address of desired token
    @param fromSushiPool Pool from which to remove liquidity
    @param incomingLP Quantity of LP to remove from pool
    @param minTokensRec Minimum quantity of tokens to receive
    @param swapTargets Execution targets for swaps
    @param allowanceTargets Targets to approve for swaps
    @param swapData DEX swap data
    @param affiliate Affiliate address
    @param shouldSellEntireBalance True if amountIn is determined at execution time (i.e. contract is caller)
    */
    function ZapOut(
        address toToken,
        address fromSushiPool,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        address[] memory allowanceTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokenBought) {
        incomingLP = _pullTokens(
            fromSushiPool,
            incomingLP,
            shouldSellEntireBalance
        );

        (uint256 amountA, uint256 amountB) =
            _removeLiquidity(fromSushiPool, incomingLP);

        tokenBought = _swapTokens(
            fromSushiPool,
            amountA,
            amountB,
            toToken,
            swapTargets,
            allowanceTargets,
            swapData
        );

        require(tokenBought >= minTokensRec, "High slippage");

        uint256 tokensRec = _transfer(toToken, tokenBought, affiliate);

        emit zapOut(msg.sender, fromSushiPool, toToken, tokensRec);

        return tokensRec;
    }

    function _transfer(
        address token,
        uint256 amount,
        address affiliate
    ) internal returns (uint256 tokensTransferred) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                amount,
                affiliate,
                true
            );

            msg.sender.transfer(amount.sub(totalGoodwillPortion));
        } else {
            totalGoodwillPortion = _subtractGoodwill(
                token,
                amount,
                affiliate,
                true
            );

            IERC20(token).safeTransfer(
                msg.sender,
                amount.sub(totalGoodwillPortion)
            );
        }
        tokensTransferred = amount.sub(totalGoodwillPortion);
    }

    function _removeLiquidity(address fromSushiPool, uint256 incomingLP)
        internal
        returns (uint256 amountA, uint256 amountB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);

        require(
            address(pair) != address(0),
            "Error: Invalid Sushipool Address"
        );

        address token0 = pair.token0();
        address token1 = pair.token1();

        _approveToken(fromSushiPool, address(sushiSwapRouter), incomingLP);

        (amountA, amountB) = sushiSwapRouter.removeLiquidity(
            token0,
            token1,
            incomingLP,
            1,
            1,
            address(this),
            deadline
        );
        require(amountA > 0 && amountB > 0, "Removed insufficient liquidity");
    }

    function _swapTokens(
        address fromSushiPool,
        uint256 amountA,
        uint256 amountB,
        address toToken,
        address[] memory swapTargets,
        address[] memory allowanceTargets,
        bytes[] memory swapData
    ) internal returns (uint256 tokensBought) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);
        address token0 = pair.token0();
        address token1 = pair.token1();

        //swap token0 to toToken
        if (token0 == toToken) {
            tokensBought = tokensBought.add(amountA);
        } else {
            tokensBought = tokensBought.add(
                _fillQuote(
                    token0,
                    toToken,
                    amountA,
                    swapTargets[0],
                    allowanceTargets[0],
                    swapData[0]
                )
            );
        }

        //swap token1 to toToken
        if (token1 == toToken) {
            tokensBought = tokensBought.add(amountB);
        } else {
            //swap token using 0x swap
            tokensBought = tokensBought.add(
                _fillQuote(
                    token1,
                    toToken,
                    amountB,
                    swapTargets[1],
                    allowanceTargets[1],
                    swapData[1]
                )
            );
        }
    }

    function _fillQuote(
        address fromTokenAddress,
        address toToken,
        uint256 amount,
        address swapTarget,
        address allowanceTarget,
        bytes memory swapData
    ) internal returns (uint256) {
        uint256 valueToSend;

        if (fromTokenAddress == wmaticTokenAddress && toToken == address(0)) {
            IWETH(wmaticTokenAddress).withdraw(amount);
            return amount;
        }

        if (fromTokenAddress == address(0)) {
            valueToSend = amount;
        } else {
            _approveToken(fromTokenAddress, allowanceTarget, amount);
        }

        uint256 initialBalance = _getBalance(toToken);

        (bool success, ) = swapTarget.call.value(valueToSend)(swapData);
        require(success, "Error Swapping Tokens");

        uint256 finalBalance = _getBalance(toToken).sub(initialBalance);

        require(finalBalance > 0, "Swapped to Invalid Intermediate");

        return finalBalance;
    }

    /**
    @notice Utility function to determine quantity and addresses of tokens being removed
    @param fromSushiPool Pool from which to remove liquidity
    @param liquidity Quantity of LP tokens to remove.
    @return  amountA- amountB- Quantity of token0 and token1 removed
    @return  token0- token1- Addresses of the underlying tokens to be removed
    */
    function removeLiquidityReturn(address fromSushiPool, uint256 liquidity)
        external
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            address token0,
            address token1
        )
    {
        IUniswapV2Pair pair = IUniswapV2Pair(fromSushiPool);
        token0 = pair.token0();
        token1 = pair.token1();

        uint256 balance0 = IERC20(token0).balanceOf(fromSushiPool);
        uint256 balance1 = IERC20(token1).balanceOf(fromSushiPool);

        uint256 _totalSupply = pair.totalSupply();

        amountA = liquidity.mul(balance0) / _totalSupply;
        amountB = liquidity.mul(balance1) / _totalSupply;
    }

    function() external payable {
        require(msg.sender != tx.origin, "Do not send ETH directly");
    }
}
