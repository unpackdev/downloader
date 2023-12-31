/**
 * Website: https://moecoin.xyz/
 * Twitter: https://twitter.com/MoneyMoeEth
 * Telegram: https://t.me/moecoinETH
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract MoneyOverEverything is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Hardcoded addresses for Ethereum mainnet
    address constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address public marketingAddress = 0x3012eD9Ed4A3E957FB3dd29815b7048A354e8615;
    uint256 public buyTax = 20;  // 20% initially
    uint256 public sellTax = 25; // 25% initially
    uint256 public numberOfBuys = 0;

    event TaxesUpdated(uint256 newBuyTax, uint256 newSellTax);

    constructor() ERC20("MONEY OVER EVERYTHING", "$MOE") {
        uint256 totalSupply = 19_860_000 * 10 ** decimals();
        uint256 developerTokens = totalSupply.mul(6).div(100); // 6% for developer

        _mint(address(this), totalSupply.sub(developerTokens)); // Contract gets the remainder
        _mint(msg.sender, developerTokens); // Developer gets their 6%

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(ROUTER_ADDRESS);
        uniswapV2Router = _uniswapV2Router;

        // Initialize the uniswapV2Pair
        uniswapV2Pair = IUniswapV2Factory(FACTORY_ADDRESS).createPair(address(this), _uniswapV2Router.WETH());
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external onlyOwner {
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");
        require(balanceOf(address(this)) >= tokenAmount, "Insufficient tokens in contract");

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _updateTaxes() internal {
        numberOfBuys++;

        if (numberOfBuys > 10) {
            buyTax = buyTax.sub(2); // Reduce buy tax by 2%
            sellTax = sellTax.sub(2); // Reduce sell tax by 2%
        }

        if (buyTax < 2) {
            buyTax = 2; // Set a minimum limit to buy tax
        }

        if (sellTax < 2) {
            sellTax = 2; // Set a minimum limit to sell tax
        }

        emit TaxesUpdated(buyTax, sellTax);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (sender != owner() && recipient != owner()) {
            uint256 tax = 0;

            if (sender == uniswapV2Pair) { // Buy
                tax = amount.mul(buyTax).div(100);
                numberOfBuys++;
            } else if (recipient == uniswapV2Pair) { // Sell
                tax = amount.mul(sellTax).div(100);
            }

            if (tax > 0) {
                super._transfer(sender, marketingAddress, tax);
                amount = amount.sub(tax);
            }
        }

        super._transfer(sender, recipient, amount);
    }
}
