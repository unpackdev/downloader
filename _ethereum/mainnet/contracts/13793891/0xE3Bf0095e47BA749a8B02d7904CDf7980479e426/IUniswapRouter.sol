// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

interface IUniswapRouter {

    event LiquidityAdded(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
//        virtual
//        override
        payable
//        ensure(deadline)
        returns (uint[] memory amounts);
//    {
//        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');
//        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);
//        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
//        IWETH(WETH).deposit{value: amounts[0]}();
//        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
//        _swap(amounts, path, to);
//    }

        function swapTokensForExactTokens(
            uint amountOut,
            uint amountInMax,
            address[] calldata path,
            address to,
            uint deadline)
        external
//        virtual
//        override
        returns (uint[] memory amounts);
//    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
//        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);
//        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');
//        TransferHelper.safeTransferFrom(
//            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
//        );
//        _swap(amounts, path, to);
//    }

}
