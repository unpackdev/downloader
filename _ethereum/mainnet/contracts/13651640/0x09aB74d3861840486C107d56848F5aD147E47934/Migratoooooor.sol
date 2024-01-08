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
    IUniswapV2Pair public immutable ohGeezLP;
    IUniswapV2Pair public immutable levxLP;
    address public immutable weth;
    address public immutable factory;
    ISwapper public immutable swapper;

    constructor(
        address _ohGeez,
        address _levx,
        IUniswapV2Pair _ohGeezLP,
        IUniswapV2Pair _levxLP,
        IUniswapV2Router01 _router,
        ISwapper _swapper
    ) {
        ohGeez = _ohGeez;
        ohGeezLP = _ohGeezLP;
        levx = _levx;
        levxLP = _levxLP;
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
        ohGeezLP.permit(msg.sender, address(this), liquidity, deadline, v, r, s);
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

        (uint256 amountOhGeez, uint256 amountWeth) = removeLiquidity(liquidity);
        swapper.swap(amountOhGeez, address(this));
        (, uint256 amountWethAdded) = addLiquidity(amountOhGeez * 10, amountWethAddedMin, to);
        require(amountWethAdded >= amountWethAddedMin, "LEVX: NOT_ENOUGH_WETH_ADDED");

        if (amountWeth > amountWethAdded) {
            IERC20(weth).safeTransfer(to, amountWeth - amountWethAdded);
        }
    }

    function removeLiquidity(uint256 liquidity) internal returns (uint256 amountOhGeez, uint256 amountWeth) {
        ohGeezLP.transferFrom(msg.sender, address(ohGeezLP), liquidity);
        (uint256 amount0, uint256 amount1) = ohGeezLP.burn(address(this));
        (address token0, ) = UniswapV2Library.sortTokens(ohGeez, weth);
        (amountOhGeez, amountWeth) = ohGeez == token0 ? (amount0, amount1) : (amount1, amount0);
    }

    function addLiquidity(
        uint256 amountLevxDesired,
        uint256 amountWethDesired,
        address to
    ) internal returns (uint256 amountLevxAdded, uint256 amountWethAdded) {
        (amountLevxAdded, amountWethAdded) = _addLiquidity(levx, weth, amountLevxDesired, amountWethDesired);
        IERC20(levx).safeTransfer(address(levxLP), amountLevxAdded);
        IERC20(weth).safeTransfer(address(levxLP), amountWethAdded);
        levxLP.mint(to);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal view returns (uint256 amountA, uint256 amountB) {
        IUniswapV2Factory _factory = IUniswapV2Factory(factory);
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
