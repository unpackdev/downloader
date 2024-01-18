//SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;
import "./IUniswapV3Factory.sol";
import "./ISwapRouter.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IV3SwapRouter.sol";
import "./OracleLibrary.sol";
import "./TransferHelper.sol";

contract DexAggregator {
    ///@notice uniswapv3 router address
    address public univ3router = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    ///@notice uniswap v2 router address
    address public univ2router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    ///@notice sushiswap router address
    address public sushirouter;
    ///@notice uniswap v3 factory address
    address public univ3factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    ///@notice uniswap v2 factory address
    address public univ2factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    ///@notice sushiswap factory address
    address public sushifactory;
    ///@notice sushiswap router address
    address public SWAP_ROUTER_02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    ///@notice uniswap v3 router
    IV3SwapRouter public immutable swapRouter02 = IV3SwapRouter(SWAP_ROUTER_02);

    ///@notice constructor for the dex aggregator
    ///@param _sushifactory The factory address of sushiswap
    ///@param _sushirouter The router address of suhsiswap
    constructor(address _sushifactory, address _sushirouter) {
        sushifactory = _sushifactory;
        sushirouter = _sushirouter;
    }

    ///@notice function to calculate the time weighted average amount of token out based on the amount of token in
    ///@param tokenIn The address of the token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param secondsAgo The seconds that we want want to consider
    function uniswapv3rate(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint32 secondsAgo
    ) private view returns (uint256, uint24) {
        uint16[] memory feearray = new uint16[](4);
        feearray[0] = 100;
        feearray[1] = 500;
        feearray[2] = 3000;
        feearray[3] = 10000;
        uint256 price;
        uint24 feeb;
        address pool;
        address tokeni = tokenIn;
        address tokeno = tokenOut;
        uint128 amounti = amountIn;

        for (uint256 i; i < 4; ++i) {
            pool = IUniswapV3Factory(univ3factory).getPool(
                tokenIn,
                tokenOut,
                feearray[i]
            );

            if (poolandamountcheck(pool, tokenIn, amountIn)) {
                uint32[] memory secondsAgos = new uint32[](2);
                secondsAgos[0] = secondsAgo;
                secondsAgos[1] = 0;

                (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool)
                    .observe(secondsAgos);

                int56 tickCumulativesDelta = tickCumulatives[1] -
                    tickCumulatives[0];

                int24 tick = int24(tickCumulativesDelta / secondsAgo);

                if (
                    tickCumulativesDelta < 0 &&
                    (tickCumulativesDelta % secondsAgo != 0)
                ) {
                    tick--;
                }
                uint256 amountOut;
                amountOut = OracleLibrary.getQuoteAtTick(
                    tick,
                    amounti,
                    tokeni,
                    tokeno
                );
                uint256 feeamount = (amountOut * feearray[i]) / 1000000;
                uint256 swapamount;
                swapamount = amountOut - feeamount;

                if (swapamount > price) {
                    price = swapamount;
                    feeb = feearray[i];
                }
            }
        }

        if (price == 0) {
            return (0, 0);
        }
        return (price, feeb);
    }

    ///@notice function to check if the check if the pool exist and has amount greater than amountIn of token
    ///@param pool The address of the pool
    ///@param token The address of the token whose amount we want to check
    ///@param amountIn The minimum amount that we want the pool to have
    function poolandamountcheck(
        address pool,
        address token,
        uint256 amountIn
    ) private view returns (bool pass) {
        if (pool != address(0) && checkAmount(token, pool) > amountIn) {
            return true;
        }
        return false;
    }

    ///@notice function to calculate the amount of token out and fees in uniswap v2 and , given the amount in at a particular time
    ///@param tokenIn The token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param flag 0 for uniswap rate and 1 for sushiswap rate except for these it (returns 0.0)
    function univ2andsushiswaprate(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 flag
    ) private view returns (uint256, uint24) {
        address _factory;
        address _router;

        if (flag == 0) {
            _factory = univ2factory;
            _router = univ2router;
        } else if (flag == 1) {
            _factory = sushifactory;
            _router = sushirouter;
        } else {
            return (0, 0);
        }

        address pool = IUniswapV2Factory(_factory).getPair(tokenIn, tokenOut);

        if (!(poolandamountcheck(pool, tokenIn, amountIn))) {
            return (0, 0);
        }

        address[] memory tokens = new address[](2);
        tokens[0] = tokenIn;
        tokens[1] = tokenOut;
        uint256[] memory prices = IUniswapV2Router02(_router).getAmountsOut(
            amountIn,
            tokens
        );
        return (prices[1], 3000);
    }

    ///@notice function will return all the prices if 0 is passed as flag and will return best value if flag is passed as 1
    ///@param tokenIn The token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param flag 0 for uniswap rate and 1 for sushiswap rate except for these it (returns 0.0)
    function getRates(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint8 flag
    )
        private
        view
        returns (
            uint256[] memory,
            uint8,
            uint24
        )
    {
        require(flag == 1 || flag == 2, "Flag value inncorrect");

        uint24 fees;

        uint256[] memory prices = new uint256[](3);

        (prices[0], fees) = uniswapv3rate(
            tokenIn,
            tokenOut,
            uint128(amountIn),
            uint32(2)
        );
        (prices[1], ) = univ2andsushiswaprate(tokenIn, tokenOut, amountIn, 0);
        (prices[2], ) = univ2andsushiswaprate(tokenIn, tokenOut, amountIn, 1);
        //if 1 is passed as flag then function will return all the swap rates
        if (flag == 1) {
            return (prices, 4, 0);
        }
        //if 2 is passed as flag then function will return the best swap rates
        //return value will represent the platform in which we will swap
        //1 for uniswapv3, 2 for uniswapv2, 3 for sushiswap
        else {
            uint256[] memory price = new uint256[](1);
            if (prices[0] > prices[1] && prices[0] > prices[2]) {
                price[0] = prices[0];
                return (price, 1, fees);
            } else if (prices[1] > prices[2] && prices[1] > prices[0]) {
                price[0] = prices[1];

                return (price, 2, 3000);
            } else {
                price[0] = prices[2];
                return (price, 3, 3000);
            }
        }
    }

    ///@notice function to check the balance of pool address for a particular token
    ///@param token The token address that we want to check amount of in pool
    ///@param pool The address of the pool
    function checkAmount(address token, address pool)
        private
        view
        returns (uint256)
    {
        return IERC20(token).balanceOf(pool);
    }

    ///@notice Function to swap token in uniswap v2 and sushiswap
    ///@param tokenIn The token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param amountOutMin The minimum amount of tokenOut tokens that we want
    ///@param to the address that we want the tokenOut tokens to go to after sswap
    ///@param flag 2 for swapping in uniswap v2 and 3 for sushiswap
    function swapuniv2andsushi(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 flag
    ) private {
        require(flag == 2 || flag == 3, "Incorrect Flag");

        address swaprouter;

        if (flag == 2) {
            swaprouter = univ2router;
        } else if (flag == 3) {
            swaprouter = sushirouter;
        }

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(swaprouter, amountIn);
        address[] memory path;

        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        IUniswapV2Router02(swaprouter).swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            block.timestamp
        );
    }

    ///@notice Function to swap token in uniswap v3
    ///@param tokenIn The token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param amountOutMin The minimum amount of tokenOut tokens that we want
    ///@param fees The feee that we want to use for swap
    ///@param to The address that we want the tokenOut tokens to go to after sswap
    function swapuniv3(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fees,
        address to
    ) private returns (uint256 amountOut) {
        TransferHelper.safeTransferFrom(
            tokenIn,
            msg.sender,
            address(this),
            amountIn
        );

        TransferHelper.safeApprove(tokenIn, SWAP_ROUTER_02, amountIn);

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fees,
                recipient: to,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter02.exactInputSingle(params);
    }

    ///@notice Function to swap token in uniswap v3
    ///@param tokenIn The token that we want to swap with
    ///@param tokenOut The address of the token that we want to get after swapping
    ///@param amountIn The amount of the tokenIn that we want to swap with
    ///@param amountOutMin The minimum amount of tokenOut tokens that we want
    ///@param to The address that we want the tokenOut tokens to go to after swap
    ///@param slippageallowed The percent of maxiumum slippage allowed
    function bestrateswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 slippageallowed
    ) external returns (uint256) {
        require(tokenIn != tokenOut, "Input different tokens");
        require(amountIn > 0, "Input amount should be greater than 0");
        uint256 balance0;
        uint256 balance1;
        //amount of output token with the  receiver before swapping
        balance0 = checkAmount(tokenOut, to);
        // flag to identify the dex for the swapping
        uint8 flag;
        //fees charged by the dex
        uint24 fees;
        uint256[] memory expectedamountout;
        //getting the flag and fees for the exchange
        //notice- The fees will only be used if the flag is 1, which represents uniswapv3
        (expectedamountout, flag, fees) = getRates(
            tokenIn,
            tokenOut,
            amountIn,
            2
        );

        uint256 perc = 100 - slippageallowed;
        amountOutMin = (expectedamountout[0] * perc) / 100;

        if (flag == 1) {
            swapuniv3(tokenIn, tokenOut, amountIn, 0, fees, to);
            //amount of output token with the  receiver after swapping
        } else {
            swapuniv2andsushi(
                tokenIn,
                tokenOut,
                amountIn,
                amountOutMin,
                to,
                flag
            );
        }
        //amount of output token with the  receiver after swapping
        balance1 = checkAmount(tokenOut, to);
        //amount received by the receiver after the swap
        return balance1 - balance0;
    }
}
