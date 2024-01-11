// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./Ownable.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

import "./CamelCoin.sol";

/// @title Camel Coin Converter
/// @notice Collects and converts Camel Coins to ETH, sends them to team & marketing wallets.
/// @author metacrypt.org
contract CamelCollector is Ownable {
    CamelCoin public immutable camelCoin;

    IUniswapV2Router02 public immutable uniswapRouter;
    uint256 private minTokensToSwap;

    address payable public teamWallet;
    address payable public marketingWallet;

    constructor(
        address _uniswapRouterAddress,
        address _camelCoinAddress,
        address payable _teamWallet,
        address payable _marketingWallet
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        camelCoin = CamelCoin(_camelCoinAddress);

        setMinTokensToSwap(10000 * (10**camelCoin.decimals()));
        setDistributors(_teamWallet, _marketingWallet);
    }

    function setMinTokensToSwap(uint256 _minTokensToSwap) public onlyOwner {
        minTokensToSwap = _minTokensToSwap;
    }

    function setDistributors(address payable _teamWallet, address payable _marketingWallet) public onlyOwner {
        teamWallet = _teamWallet;
        marketingWallet = _marketingWallet;
    }

    // function setSplits(uint256 _splitTeam, uint256 _splitMarketing) public onlyOwner {
    //     splitTeam = _splitTeam;
    //     splitMarketing = _splitMarketing;
    // }

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
        if (teamWallet != address(0) && address(this).balance > 0) {
            (bool sent, ) = teamWallet.call{value: (address(this).balance)}("");
            require(sent, "CamelConverter: Transfer Failed");
        }
    }

    receive() external payable {}
}