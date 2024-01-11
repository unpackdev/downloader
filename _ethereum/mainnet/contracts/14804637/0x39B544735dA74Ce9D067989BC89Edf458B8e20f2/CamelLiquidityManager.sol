// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./CamelCoin.sol";

/// @title Camel Coin Liquidity Manager
/// @author metacrypt.org
contract CamelLiquidityManager is Ownable {
    CamelCoin public immutable camelCoin;

    IUniswapV2Router02 public immutable uniswapRouter;
    address public immutable uniswapPair;

    uint256 public minTokensToSwap;

    constructor(address _uniswapRouterAddress, address _camelCoinAddress) {
        require(_uniswapRouterAddress != address(0), "Uniswap Router can not be address(0)");
        require(_camelCoinAddress != address(0), "Camel Coin can not be address(0)");
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        camelCoin = CamelCoin(_camelCoinAddress);

        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(_camelCoinAddress, uniswapRouter.WETH());

        setMinTokensToAdd(100 * (10**camelCoin.decimals()));
    }

    function setMinTokensToAdd(uint256 _minTokensToSwap) public onlyOwner {
        minTokensToSwap = _minTokensToSwap;
    }

    function addLiquidity() public {
        uint256 balanceToAdd = camelCoin.balanceOf(address(this));

        camelCoin.approve(address(uniswapRouter), balanceToAdd);

        uniswapRouter.addLiquidityETH{value: address(this).balance}(
            address(camelCoin),
            balanceToAdd,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 1
        );
    }

    function autoSwap() internal returns (bool) {
        uint256 balanceToSwap = (camelCoin.balanceOf(address(this)) * 2) / 5;

        if (balanceToSwap < minTokensToSwap) {
            return false;
        }

        // Let's approve the exact swap amount.
        camelCoin.approve(address(uniswapRouter), balanceToSwap);

        // Router Path Token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(camelCoin);
        path[1] = uniswapRouter.WETH();

        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceToSwap,
            0, // slippage is unavoidable
            path,
            address(this),
            block.timestamp + 1
        );

        return true;
    }

    function processFunds() external {
        if (autoSwap()) {
            addLiquidity();
        }
    }

    function recoverToken(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(camelCoin), "Can not recover Camel Coin");
        IERC20(tokenAddress).transfer(owner(), tokenAmount == 0 ? IERC20(tokenAddress).balanceOf(address(this)) : tokenAmount);
    }

    receive() external payable {}
}
