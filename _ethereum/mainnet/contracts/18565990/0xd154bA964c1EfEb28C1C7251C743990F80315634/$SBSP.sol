// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./ERC20.sol";

contract SBSP is ERC20 {

    IUniswapV2Router02 public immutable uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public immutable uniswapV2Pair;
    address public immutable devWallet;

    uint256 public maxTransactionAmount;
    uint256 public maxWallet;

    uint256 private launchBlock;
    uint256 private firstBlocks = 10;
    uint256 private firstBlocksFee = 30;

    uint256 private constant PERCENT_2 = 2;
    uint256 private constant PERCENT_95 = 95;
    uint256 private constant PERCENT_100 = 100;

    bool public tradingActive;
    bool public limitsDisabled;

    mapping(address => bool) private excludedMaxTransactionAmount;

    constructor(address devWallet_) ERC20("A FEW MOMENTS LATER WE ALL EARN", "$SBSP") {
        uint256 maxSupply = 1_000_000_000e18;
        maxTransactionAmount = maxSupply * PERCENT_2 / PERCENT_100;
        maxWallet = maxSupply * PERCENT_2 / PERCENT_100;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        excludeFromMaxTransaction(address(uniswapV2Router));
        excludeFromMaxTransaction(uniswapV2Pair);
        excludeFromMaxTransaction(devWallet_);
        excludeFromMaxTransaction(_feeKeeper);
        excludeFromMaxTransaction(address(this));

        _mint(address(this), maxSupply * PERCENT_95 / PERCENT_100);
        _mint(devWallet_, maxSupply * (PERCENT_100 - PERCENT_95) / PERCENT_100);
        devWallet = devWallet_;
    }

    receive() external payable {}

    function enableTrading() external payable {
        require(msg.sender == devWallet, "Only dev wallet have permission to add liquidity");
        require(!tradingActive, "Token launched");
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        uniswapV2Router.addLiquidityETH{value : msg.value}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );
        tradingActive = true;
        launchBlock = block.number;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingActive || from == devWallet || to == devWallet || from == address(this) || to == address(this), "Trading is not active");

        bool isInFirstBlocks = launchBlock + firstBlocks >= block.number;

        if (tradingActive && !isInFirstBlocks && !limitsDisabled) {
            limitsDisabled = true;
        }

        if (
            from != devWallet &&
            to != devWallet &&
            !limitsDisabled
        ) {
            if (from == uniswapV2Pair && !excludedMaxTransactionAmount[to]) {
                require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount");
                require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
            }

            if (to == uniswapV2Pair && !excludedMaxTransactionAmount[from]) {
                require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount");
            }
        }

        _fee = 0;
        if (isInFirstBlocks && tradingActive) {
            _fee = amount * firstBlocksFee / PERCENT_100;
        } 

        super._transfer(from, to, amount);
        
    }

    function excludeFromMaxTransaction(address addr) private {
        excludedMaxTransactionAmount[addr] = true;
    }
}