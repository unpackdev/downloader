// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

import "./IWETH.sol";
import "./IUniswapV2Factory.sol";
import "./IHelioswapFactory.sol";
import "./ISwapRouter.sol";
import "./Multicall.sol";
import "./BytesLib.sol";

// TOKordinator
/// @title TokenStand Coordinator - Fantastic coordinator for swapping
/// @author Anh Dao Tuan <anh.dao@sotatek.com>

contract TOKordinator is Ownable, ReentrancyGuard, Multicall {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using UniswapV2Library for IUniswapV2Pair;
    using HelioswapLibrary for IHelioswap;
    using BytesLib for bytes;

    IWETH internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    IUniswapV2Factory internal uniswapV2 = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV2Factory internal sushiswap = IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);
    IHelioswapFactory internal helioswap = IHelioswapFactory(0x9f07b190779d06e5f6CaCcAC251b240D8946741E);

    // UniswapV3
    ISwapRouter internal swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    event SwappedOnTheOther(
        IERC20 indexed fromToken,
        IERC20 indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn,
        uint256[] distribution
    );

    event SwappedOnUniswapV3(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn
    );

    uint256 internal constant DEXES_COUNT = 3;

    constructor() {}
    receive() external payable {}

    function swapOnTheOther(
        IERC20[][] calldata path,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution
    ) public payable nonReentrant returns (uint256 returnAmount) {
        function(IERC20[] calldata, uint256)[DEXES_COUNT] memory reserves = [
            _swapOnUniswapV2,
            _swapOnSushiswap,
            _swapOnHelioswap
        ];

        require(
            distribution.length <= reserves.length,
            'TOKordinator: distribution array should not exceed reserves array size.'
        );

        uint256 parts = 0;
        uint256 lastNonZeroIndex = 0;
        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] > 0) {
                parts = parts.add(distribution[i]);
                lastNonZeroIndex = i;
            }
        }

        IERC20 fromToken = IERC20(path[lastNonZeroIndex][0]);
        IERC20 destToken = IERC20(path[lastNonZeroIndex][path[lastNonZeroIndex].length - 1]);

        if (parts == 0) {
            if (address(fromToken) == address(0)) {
                (bool success, ) = msg.sender.call{value: msg.value}('');
                require(success, 'TOKordinator: transfer failed.');
                return msg.value;
            }
            return amount;
        }

        if (address(fromToken) != address(0)) {
            fromToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        uint256 remainingAmount = address(fromToken) == address(0)
            ? address(this).balance
            : fromToken.balanceOf(address(this));

        for (uint256 i = 0; i < distribution.length; i++) {
            if (distribution[i] == 0) {
                continue;
            }

            uint256 swapAmount = amount.mul(distribution[i]).div(parts);
            if (i == lastNonZeroIndex) {
                swapAmount = remainingAmount;
            }
            remainingAmount -= swapAmount;
            reserves[i](path[i], swapAmount);
        }

        returnAmount = address(destToken) == address(0) ? address(this).balance : destToken.balanceOf(address(this));
        require(returnAmount >= minReturn, 'TOKordinator: return amount was not enough');

        if (address(destToken) == address(0)) {
            msg.sender.transfer(returnAmount);
        } else {
            destToken.safeTransfer(msg.sender, returnAmount);
        }

        uint256 remainingFromToken = address(fromToken) == address(0)
            ? address(this).balance
            : fromToken.balanceOf(address(this));
        if (remainingFromToken > 0) {
            if (address(fromToken) == address(0)) {
                msg.sender.transfer(remainingFromToken);
            } else {
                fromToken.safeTransfer(msg.sender, remainingFromToken);
            }
        }

        emit SwappedOnTheOther(fromToken, destToken, amount, returnAmount, minReturn, distribution);
    }

    function getUniswapV2AmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(uniswapV2, amountIn, realPath);
    }

    function getSushiswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        IERC20[] memory realPath = formatPath(path);
        return UniswapV2Library.getAmountsOut(sushiswap, amountIn, realPath);
    }

    function getHelioswapAmountsOut(uint256 amountIn, IERC20[] memory path) public view returns (uint256[] memory) {
        return HelioswapLibrary.getReturns(helioswap, amountIn, path);
    }

    function formatPath(IERC20[] memory path) public view returns (IERC20[] memory realPath) {
        realPath = new IERC20[](path.length);

        for (uint256 i; i < path.length; i++) {
            if (address(path[i]) == address(0)) {
                realPath[i] = weth;
                continue;
            }
            realPath[i] = path[i];
        }
    }

    function _swapOnUniswapV2(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = uniswapV2.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(uniswapV2, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            path[0].safeTransfer(address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(uniswapV2.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            uniswapV2.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnSushiswap(IERC20[] calldata path, uint256 amount) internal {
        IERC20[] memory realPath = formatPath(path);

        IUniswapV2Pair pair = sushiswap.getPair(realPath[0], realPath[1]);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(sushiswap, amount, realPath);

        if (address(path[0]) == address(0)) {
            weth.deposit{value: amounts[0]}();
            assert(weth.transfer(address(pair), amounts[0]));
        } else {
            path[0].safeTransfer(address(pair), amounts[0]);
        }

        for (uint256 i; i < realPath.length - 1; i++) {
            (address input, address output) = (address(realPath[i]), address(realPath[i + 1]));
            (address token0, ) = sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < realPath.length - 2
                ? address(sushiswap.getPair(IERC20(output), realPath[i + 2]))
                : address(this);
            sushiswap.getPair(IERC20(input), IERC20(output)).swap(amount0Out, amount1Out, to, new bytes(0));
        }

        if (address(path[path.length - 1]) == address(0)) {
            weth.withdraw(weth.balanceOf(address(this)));
        }
    }

    function _swapOnHelioswapInternal(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount
    ) internal {
        (IHelioswap pool,,,,,) = helioswap.pools(fromToken, destToken);

        uint256 returnAmount = pool.getReturn(fromToken, destToken, amount);

        if (address(fromToken) != address(0)) {
            fromToken.safeApprove(address(pool), amount);
            pool.swap(fromToken, destToken, amount, returnAmount);
        } else {
            pool.swap{value: amount}(fromToken, destToken, amount, returnAmount);
        }
    }

    function _swapOnHelioswap(IERC20[] calldata path, uint256 amount) internal {
        uint256[] memory amounts = HelioswapLibrary.getReturns(helioswap, amount, path);

        for (uint256 i; i < path.length - 1; i++) {
            _swapOnHelioswapInternal(path[i], path[i + 1], amounts[i]);
        }
    }

    function swapOnUniswapV3(
        IERC20 tokenIn,
        bytes memory path,
        address recipient,
        uint256 deadline,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable nonReentrant returns (uint256 returnAmount) {
        if (address(tokenIn) == address(0)) {
            require(msg.value >= amountIn, 'TOKordinator: value does not enough');
        }

        IERC20 tokenOut = IERC20(path.getTokenOut());

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            path,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum
        );

        if (address(tokenIn) == address(0)) {
            returnAmount = swapRouter.exactInput{value: amountIn}(params);
        } else {
            tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
            tokenIn.safeApprove(address(swapRouter), amountIn);

            returnAmount = swapRouter.exactInput(params);
        }
        swapRouter.refundETH();

        emit SwappedOnUniswapV3(tokenIn, tokenOut, amountIn, returnAmount, amountOutMinimum);
    }

    // emergency case
    function rescueFund(IERC20 token) public onlyOwner {
        if (address(token) == address(0)) {
            (bool success, ) = msg.sender.call{value: address(this).balance}('');
            require(success, 'TOKordinator: fail to rescue Ether');
        } else {
            token.safeTransfer(msg.sender, token.balanceOf(address(this)));
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'TOKordinator: identical addresses');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOKordinator: zero address');
    }
}
