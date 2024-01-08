// SPDX-License-Identifier: WTFPL

pragma solidity =0.8.3;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Factory.sol";
import "./UniswapV2Library.sol";

interface ISwapper {
    function swap(uint256 amount, address to) external;
}

contract Migratoooooor {
    using SafeERC20 for IERC20;

    address public immutable ohGeez;
    address public immutable levx;
    address public immutable weth;
    address public immutable factory;
    ISwapper public immutable swapper;

    constructor(
        address _ohGeez,
        address _levx,
        IUniswapV2Router01 _router,
        ISwapper _swapper
    ) {
        ohGeez = _ohGeez;
        levx = _levx;
        weth = _router.WETH();
        factory = _router.factory();
        swapper = _swapper;
    }

    function migrateWithPermit(
        uint256 liquidity,
        uint256 amountWethAddedMin,
        uint256 deadline,
        address to,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, ohGeez, weth));
        pair.permit(msg.sender, address(this), liquidity, deadline, v, r, s);

        migrate(liquidity, amountWethAddedMin, deadline, to);
    }

    // msg.sender should have approved 'liquidity' amount of LP token of 'OH-GEEZ' and 'WETH'
    function migrate(
        uint256 liquidity,
        uint256 amountWethAddedMin,
        uint256 deadline,
        address to
    ) public {
        require(deadline >= block.timestamp, "LEVX: EXPIRED");

        (uint256 amountOhGeez, uint256 amountWeth) = removeLiquidity(ohGeez, weth, liquidity, 0, 0);
        swapper.swap(amountOhGeez, address(this));
        (, uint256 amountWethAdded) = addLiquidity(levx, weth, amountOhGeez * 10, amountWethAddedMin, to);
        require(amountWethAdded >= amountWethAddedMin, "LEVX: NOT_ENOUGH_WETH_ADDED");

        if (amountWeth > amountWethAdded) {
            IERC20(weth).safeTransfer(to, amountWeth - amountWethAdded);
        }
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
        pair.transferFrom(msg.sender, address(pair), liquidity);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "LEVX: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "LEVX: INSUFFICIENT_B_AMOUNT");
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    ) internal returns (uint256 amountA, uint256 amountB) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        IERC20(tokenA).safeTransfer(pair, amountA);
        IERC20(tokenB).safeTransfer(pair, amountB);
        IUniswapV2Pair(pair).mint(to);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        IUniswapV2Factory _factory = IUniswapV2Factory(factory);
        if (_factory.getPair(tokenA, tokenB) == address(0)) {
            _factory.createPair(tokenA, tokenB);
        }
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(address(_factory), tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
}
