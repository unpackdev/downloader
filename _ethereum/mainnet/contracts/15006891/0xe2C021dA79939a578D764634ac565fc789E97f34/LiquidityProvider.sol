// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./IETHVault.sol";
import "./UniswapV2Library.sol";
import "./TransferHelper.sol";

contract LiquidityProvider is Ownable {
    address public immutable vault;
    address public immutable token;
    address public immutable treasury;
    address public immutable factory;
    address public immutable weth;
    address internal immutable _pair;
    address internal immutable _token0;
    uint256 public lpRatio;

    event SetLPRatio(uint256 lpRatio);
    event Receive(address indexed from, uint256 amount);
    event SwapETH(uint256 amountETHIn, uint256 amountTokenOut);
    event AddLiquidity(
        uint256 amount,
        uint256 amountTokenIn,
        uint256 amountETHIn,
        uint256 amountTokenLP,
        uint256 amountETHLP,
        uint256 liquidity
    );

    constructor(
        address _vault,
        address _token,
        address _treasury,
        address _factory,
        address _weth,
        uint256 _lpRatio
    ) {
        require(_lpRatio <= 10**18, "LP: INVALID_LP_RATIO");

        vault = _vault;
        token = _token;
        treasury = _treasury;
        factory = _factory;
        weth = _weth;
        lpRatio = _lpRatio;

        _pair = UniswapV2Library.pairFor(_factory, _weth, _token);
        (address token0, ) = UniswapV2Library.sortTokens(_weth, _token);
        _token0 = token0;
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function setLPRatio(uint256 _lpRatio) external onlyOwner {
        require(_lpRatio <= 10**18, "LP: INVALID_LP_RATIO");

        lpRatio = _lpRatio;

        emit SetLPRatio(_lpRatio);
    }

    function addLiquidityAndSwap(
        uint256 amount,
        uint256 amountTokenInLP,
        uint256 amountTokenMinLP,
        uint256 amountETHMinLP,
        uint256 amountETHInSwap,
        uint256 amountTokenOutMinSwap
    ) external onlyOwner {
        _addLiquidity(amount, amountTokenInLP, amountTokenMinLP, amountETHMinLP);
        _swap(amountETHInSwap, amountTokenOutMinSwap);
    }

    function addLiquidity(
        uint256 amount,
        uint256 amountTokenIn,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) external onlyOwner {
        _addLiquidity(amount, amountTokenIn, amountTokenMin, amountETHMin);
    }

    function _addLiquidity(
        uint256 amount,
        uint256 amountTokenIn,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) internal {
        IETHVault(vault).withdraw(amount, address(this));

        uint256 amountETHIn = (amount * lpRatio) / (10**18);
        (uint256 amountToken, uint256 amountETH) = _addLiquidity(
            token,
            weth,
            amountTokenIn,
            amountETHIn,
            amountTokenMin,
            amountETHMin
        );

        TransferHelper.safeTransferFrom(token, treasury, _pair, amountToken);
        IWETH(weth).deposit{value: amountETH}();
        assert(IWETH(weth).transfer(_pair, amountETH));
        uint256 liquidity = IUniswapV2Pair(_pair).mint(treasury);

        emit AddLiquidity(amount, amountTokenIn, amountETHIn, amountToken, amountETH, liquidity);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "LP: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "LP: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function swap(uint256 amountETHIn, uint256 amountTokenOutMin) external onlyOwner {
        _swap(amountETHIn, amountTokenOutMin);
    }

    function _swap(uint256 amountETHIn, uint256 amountTokenOutMin) internal {
        require(amountETHIn <= address(this).balance, "LP: INSUFFICIENT_ETH");

        (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(factory, weth, token);
        uint256 amountOut = UniswapV2Library.getAmountOut(amountETHIn, reserveIn, reserveOut);
        require(amountOut >= amountTokenOutMin, "LP: INSUFFICIENT_OUTPUT_AMOUNT");

        IWETH(weth).deposit{value: amountETHIn}();
        assert(IWETH(weth).transfer(_pair, amountETHIn));

        (uint256 amount0Out, uint256 amount1Out) = weth == _token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
        IUniswapV2Pair(_pair).swap(amount0Out, amount1Out, treasury, new bytes(0));

        emit SwapETH(amountETHIn, amountOut);
    }
}
