// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./CamelCoin.sol";

/// @title Camel Coin Sandstorm Collector
/// @notice Collects and converts Camel Coins to ETH, holds until Camel Distributor is available.
/// @author metacrypt.org
contract CamelSandstormCollector is Ownable {
    CamelCoin public immutable camelCoin;

    IUniswapV2Router02 public immutable uniswapRouter;
    uint256 private minTokensToSwap;

    address payable camelDistributor;

    constructor(address _uniswapRouterAddress, address _camelCoinAddress) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        camelCoin = CamelCoin(_camelCoinAddress);

        setMinTokensToSwap(100 * (10**camelCoin.decimals()));
    }

    function setMinTokensToSwap(uint256 _minTokensToSwap) public onlyOwner {
        minTokensToSwap = _minTokensToSwap;
    }

    // The distributor can be set to address(0) to disable forwards.
    function setCamelDistributor(address payable _distributor) external onlyOwner {
        camelDistributor = _distributor;
    }

    function autoSwap() internal returns (bool) {
        uint256 balanceToSwap = camelCoin.balanceOf(address(this));

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
        autoSwap();
        if (camelDistributor != address(0)) {
            (bool sent, ) = camelDistributor.call{value: address(this).balance}("");
            require(sent, "CamelSandstormCollector: Transfer Failed");
        }
    }

    receive() external payable {}
}
