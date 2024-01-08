pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

pragma abicoder v2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

import "./ISwapRouter.sol";
import "./INonfungiblePositionManager.sol";

import "./SwapAndLiquifyStorageV3.sol";
import "./SwapAndLiquifyEvents.sol";

import "./Initializable.sol";
// import "./console.sol";


contract SwapAndLiquifyV3 is SwapAndLiquifyStorageV3, SwapAndLiquifyEvents, Initializable, Ownable {
    using SafeMath for uint256;

    ISwapRouter public swapRouter;
    INonfungiblePositionManager public nonfungiblePositionManager;

    uint24 private _uniswapV3Fee ; // 5 % fee
    int24 private _tickLower;
    int24 private _tickUpper;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // _initialized is already check in initializer
    function initialize(address _aldnAddress, address _swapRouter, address _nonFungible) public initializer{
        swapRouter = ISwapRouter(_swapRouter);
        nonfungiblePositionManager = INonfungiblePositionManager(_nonFungible);

        aldnAddress = address(_aldnAddress);

        IERC20(aldnAddress).approve(address(swapRouter), type(uint256).max);
        IERC20(nonfungiblePositionManager.WETH9()).approve(address(swapRouter), type(uint256).max);

        emit Initialized(aldnAddress, address(swapRouter));
    }

    receive() external payable {}

    // Add virtual => override by inheriting contracts to change their behavior
    function swapAndLiquify(uint256 tokenAmount) public virtual lockTheSwap {
        uint256 half = tokenAmount.div(2);
        uint256 otherHalf = tokenAmount.sub(half);
        uint256 originalEthBalance = IERC20(nonfungiblePositionManager.WETH9()).balanceOf(address(this));

        IERC20(aldnAddress).transferFrom(_msgSender(), address(this), tokenAmount);

        swapTokensForEth(half);

        uint256 spendableBalance = IERC20(nonfungiblePositionManager.WETH9()).balanceOf(address(this)).sub(originalEthBalance);

        addLiquidity(otherHalf, spendableBalance);

        emit SwapAndLiquified(half, spendableBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
      
        ISwapRouter.ExactInputSingleParams memory data =
            ISwapRouter.ExactInputSingleParams(
                aldnAddress,
                nonfungiblePositionManager.WETH9(),
                _uniswapV3Fee,
                address(this),
                (uint256)(block.timestamp).add(1000),
                tokenAmount,
                0,
                0
            );

        IERC20(aldnAddress).approve(address(swapRouter), tokenAmount);

        swapRouter.exactInputSingle(data);
    }

    function getTokens() private view returns (address token0, address token1) {
        token0 = (nonfungiblePositionManager.WETH9() < aldnAddress)
            ? nonfungiblePositionManager.WETH9()
            : aldnAddress;
        token1 = (nonfungiblePositionManager.WETH9() > aldnAddress)
            ? nonfungiblePositionManager.WETH9()
            : aldnAddress;
    }

    function getTokenBalances(uint256 tokenAmount, uint256 ethAmount)
        private
        view
        returns (uint256 balance0, uint256 balance1)
    {
        balance0 = (nonfungiblePositionManager.WETH9() < aldnAddress)
            ? ethAmount
            : tokenAmount;
        balance1 = (nonfungiblePositionManager.WETH9() > aldnAddress)
            ? ethAmount
            : tokenAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        (address token0, address token1) = getTokens();
        (uint256 balance0, uint256 balance1) = getTokenBalances(tokenAmount, ethAmount);

        uint160 sqrtPriceX96 = (sqrt(uint160(balance1)) << 96) / sqrt(uint160(balance0));

        IERC20(token0).approve(address(nonfungiblePositionManager), balance0);
        IERC20(token1).approve(address(nonfungiblePositionManager), balance1);

        INonfungiblePositionManager(address(nonfungiblePositionManager))
                .createAndInitializePoolIfNecessary{
                value: address(this).balance
            }(token0, token1, _uniswapV3Fee, sqrtPriceX96);

        INonfungiblePositionManager.MintParams memory data =
            INonfungiblePositionManager.MintParams(
                token0,
                token1,
                _uniswapV3Fee,
                _tickLower,
                _tickUpper,
                balance0,
                balance1,
                0,
                0,
                address(this),
                (uint256)(block.timestamp)
            );

        INonfungiblePositionManager(address(nonfungiblePositionManager)).mint(data);
    }

    function sqrt(uint160 x) internal pure returns (uint160 y) {
        uint160 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // Add virtual => override by inheriting contracts to change their behavior
    function initializeLiquidity(uint256 tokenAmount, uint256 ethAmount) public virtual lockTheSwap payable {
        require(msg.value >= ethAmount, "SwapAndLiquify::initialize: insufficient eth");

        IERC20(aldnAddress).transferFrom(_msgSender(), address(this), tokenAmount);
        IERC20(nonfungiblePositionManager.WETH9()).transferFrom(_msgSender(), address(this), ethAmount);

        addLiquidity(tokenAmount, ethAmount);

        emit LiquidityInitialized(tokenAmount, ethAmount);
    }

    function setSwapParam(
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    ) public {
        _uniswapV3Fee = fee;
        _tickLower = tickLower;
        _tickUpper = tickUpper;
    }

}