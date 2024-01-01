// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import "./IERC20.sol";
import "./SafeTransfer.sol";
import "./IWETH.sol";
import "./console.sol";

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}


contract CerberusRouter {
    using SafeTransfer for IERC20;
    using SafeTransfer for IWETH;

    address internal immutable owner;
    uint internal constant MIN_FEE = 0.001 * 1e18;
    address internal constant WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function withdrawFees(address wallet) public payable {
        require(msg.sender == owner, "You are not the owner");
        payable(wallet).transfer(address(this).balance);
        // SafeTransfer.safeTransferETH(wallet, address(this).balance);

    }
    fallback(bytes calldata input) external payable returns (bytes memory output) {
        
        address tokenIn;
        address tokenOut;
        address pair;
        uint256 amountOutMin;
        uint16 cerbFeeFactor;
        uint256 amountIn;
        address referrer;
        uint16 referrerFeeFactor;

        (tokenIn, tokenOut, pair,  amountOutMin, cerbFeeFactor, amountIn, referrer, referrerFeeFactor) = abi.decode(input, (address, address, address, uint256, uint16, uint256, address, uint16));

        if (address(tokenIn) == WETH) {

            require(msg.value > 0, "CerberusRouter: No ETH value sent");

            uint baseFee = (msg.value * cerbFeeFactor) / 10000;
            uint cerbFee = baseFee >= MIN_FEE ? baseFee : MIN_FEE;

            uint referrerFee = (msg.value * referrerFeeFactor) / 10000;

            amountIn = msg.value - cerbFee - referrerFee;

            if (referrerFee > 0) {
                SafeTransfer.safeTransferETH(referrer, referrerFee);
            }

            IWETH(WETH).deposit{value: amountIn}();
            assert(IWETH(WETH).transfer(pair, amountIn));

            uint balanceBefore = IERC20(tokenOut).balanceOf(msg.sender);
            address[] memory path;
            path[0] = tokenIn;
            path[1] = tokenOut;
            swapSupportingFeeOnTransferTokens(path, msg.sender, pair);
            require(
                (IERC20(tokenOut).balanceOf(msg.sender) - balanceBefore) >= amountOutMin,
                'CerberusRouter: INSUFFICIENT_OUTPUT_AMOUNT'
            );

        } else {
            
            IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
            address[] memory path;
            path[0] = tokenIn;
            path[1] = tokenOut;
            swapSupportingFeeOnTransferTokens(path, address(this), pair);
            uint amountOut = IERC20(WETH).balanceOf(address(this));
            require(amountOut >= amountOutMin, 'CerberusRouter: INSUFFICIENT_OUTPUT_AMOUNT');
            IWETH(WETH).withdraw(amountOut);

            uint cerbFee = (amountOut * cerbFeeFactor) / 10000;
            uint referrerFee = (amountOut * referrerFeeFactor) / 10000;

            uint payout = amountOut - cerbFee - referrerFee;

            if (referrerFee > 0) {
                SafeTransfer.safeTransferETH(referrer, referrerFee);
            }
            
            SafeTransfer.safeTransferETH(msg.sender, payout);
        }

        return input;
    }

    // function swapExactTokensForETHSupportingFeeOnTransferTokens(
    //     uint amountIn,
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address to,
    //     address pair
    // )
    //     internal
    //     virtual
    // {
    //     require(path[path.length - 1] == WETH, 'CerberusRouter: INVALID_PATH');
    //     IERC20(path[0]).safeTransferFrom(msg.sender, pair, amountIn);
    //     swapSupportingFeeOnTransferTokens(path, address(this), pair);
    //     uint amountOut = IERC20(WETH).balanceOf(address(this));
    //     require(amountOut >= amountOutMin, 'CerberusRouter: INSUFFICIENT_OUTPUT_AMOUNT');
    //     IWETH(WETH).withdraw(amountOut);
    //     SafeTransfer.safeTransferETH(to, amountOut);
    // }

    // function swapExactETHForTokensSupportingFeeOnTransferTokens(
    //     uint amountOutMin,
    //     address[] calldata path,
    //     address pair,
    //     address to
    // )
    //     internal
    //     virtual
    // {
    //     require(path[0] == WETH, 'CerberusRouter: INVALID_PATH');
    //     uint amountIn = msg.value;
    //     IWETH(WETH).deposit{value: amountIn}();
    //     assert(IWETH(WETH).transfer(pair, amountIn));
    //     uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
    //     swapSupportingFeeOnTransferTokens(path, to, pair);
    //     require(
    //         (IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore) >= amountOutMin,
    //         'CerberusRouter: INSUFFICIENT_OUTPUT_AMOUNT'
    //     );
    // }

    function swapSupportingFeeOnTransferTokens(address[] memory path, address _to, address pair_address) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = sortTokens(input, output);
            IUniswapV2Pair pair = IUniswapV2Pair(pair_address);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
            amountOutput = getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? pair_address : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
