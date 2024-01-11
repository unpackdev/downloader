// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import "./IImpossiblePair.sol";
import "./IImpossibleSwapFactory.sol";
import "./IImpossibleRouterExtension.sol";

import "./ImpossibleLibrary.sol";

contract ImpossibleRouterExtension is IImpossibleRouterExtension {
    address public immutable override factory;

    constructor(address _factory) {
        factory = _factory;
    }

    /**
     @notice Helper function for basic swap
     @dev Requires the initial amount to have been sent to the first pair contract
     @param amounts[] An array of trade amounts. Trades are made from arr idx 0 to arr end idx sequentially
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
    */
    function swap(uint256[] memory amounts, address[] memory path) public override {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = ImpossibleLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2 ? ImpossibleLibrary.pairFor(factory, output, path[i + 2]) : msg.sender;
            IImpossiblePair(ImpossibleLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    /**
     @notice Helper function for swap supporting fee on transfer tokens
     @dev Requires the initial amount to have been sent to the first pair contract
     @param path[] An array of token addresses. Trades are made from arr idx 0 to arr end idx sequentially
    */
    function swapSupportingFeeOnTransferTokens(address[] memory path) public override {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (uint256 amount0Out, uint256 amount1Out) = ImpossibleLibrary.getAmountOutFeeOnTransfer(
                input,
                output,
                factory
            );
            address to = i < path.length - 2 ? ImpossibleLibrary.pairFor(factory, output, path[i + 2]) : msg.sender;
            IImpossiblePair(ImpossibleLibrary.pairFor(factory, input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    /**
     @notice Helper function for adding liquidity
     @dev Logic is unchanged from uniswap-V2-Router02
     @param tokenA The address of underlying tokenA to add
     @param tokenB The address of underlying tokenB to add
     @param amountADesired The desired amount of tokenA to add
     @param amountBDesired The desired amount of tokenB to add
     @param amountAMin The min amount of tokenA to add (amountAMin:amountBDesired sets bounds on ratio)
     @param amountBMin The min amount of tokenB to add (amountADesired:amountBMin sets bounds on ratio)
     @return amountA Actual amount of tokenA added as liquidity to pair
     @return amountB Actual amount of tokenB added as liquidity to pair
    */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) public override returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        if (IImpossibleSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IImpossibleSwapFactory(factory).createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB, ) = ImpossibleLibrary.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else if (reserveA == 0) {
            amountB = amountBDesired;
        } else if (reserveB == 0) {
            amountA = amountADesired;
        } else {
            uint256 amountBOptimal = ImpossibleLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'ImpossibleRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = ImpossibleLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'ImpossibleRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     @notice Helper function for removing liquidity
     @dev Logic is unchanged from uniswap-V2-Router02
     @param tokenA The address of underlying tokenA in LP token
     @param tokenB The address of underlying tokenB in LP token
     @param pair The address of the pair corresponding to tokenA and tokenB
     @param amountAMin The min amount of underlying tokenA that has to be received
     @param amountBMin The min amount of underlying tokenB that has to be received
     @return amountA Actual amount of underlying tokenA received
     @return amountB Actual amount of underlying tokenB received
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountAMin,
        uint256 amountBMin
    ) public override returns (uint256 amountA, uint256 amountB) {
        (uint256 amount0, uint256 amount1) = IImpossiblePair(pair).burn(msg.sender);
        (address token0, ) = ImpossibleLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'ImpossibleRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'ImpossibleRouter: INSUFFICIENT_B_AMOUNT');
    }

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure virtual override returns (uint256 amountB) {
        return ImpossibleLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) public view virtual override returns (uint256 amountOut) {
        return ImpossibleLibrary.getAmountOut(amountIn, tokenIn, tokenOut, factory);
    }

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) public view virtual override returns (uint256 amountIn) {
        return ImpossibleLibrary.getAmountIn(amountOut, tokenIn, tokenOut, factory);
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ImpossibleLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint256[] memory amounts)
    {
        return ImpossibleLibrary.getAmountsIn(factory, amountOut, path);
    }
}
