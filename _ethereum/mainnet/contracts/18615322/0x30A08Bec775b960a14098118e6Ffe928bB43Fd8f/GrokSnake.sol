// SPDX-License-Identifier: MIT

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol"; 

/*
// https://twitter.com/GROKSNAKE
// https://groksnake.com/
// https://t.me/groksnakeai
*/


pragma solidity ^0.8.21;

contract GrokSnake is ERC20, Ownable {

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool private swapping;

    address private marketingWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;
    uint256 public maxSwapAmount;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 private launchedAt;
    uint256 private launchedTime;
    uint256 public blocks;

    uint256 public buyTotalFees;
    uint256 public sellTotalFees;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(uint256 => uint256) private blockSwaps;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(address indexed newWallet, address indexed oldWallet);

    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("Groksnake Ai", "GSAI") {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = 20_000_000 * 1e18;
        maxWallet = 20_000_000 * 1e18;
        swapTokensAtAmount = 100_000 * 1e18;
        maxSwapAmount = 5_000_000 * 1e18;

        marketingWallet = msg.sender;

        uint256 amountLP = (totalSupply * 90) /100;
        uint256 amountTeam = totalSupply - amountLP;

        _mint(address(this), amountLP); 
        _mint(msg.sender, amountTeam);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);
    }

    receive() external payable {}

    function openTrading() external payable onlyOwner {
        _approve(address(this), address(uniswapV2Router), totalSupply());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        blocks = 50;
        tradingActive = true;
        swapEnabled = true;
        launchedAt = block.number;
        launchedTime = block.timestamp;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        swapTokensAtAmount = newAmount * (10 ** 18);
    }

    function updateMaxSwap(uint256 newAmount) external onlyOwner {
        maxSwapAmount = newAmount * (10 ** 18);
    }

    function updateMaxTxnAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 1) / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.1%");
        maxTransactionAmount = newNum * (10 ** 18);
    }

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= ((totalSupply() * 5) / 1000) / 1e18, "Cannot set maxWallet lower than 0.5%");
        maxWallet = newNum * (10 ** 18);
    }

    function whitelistContract(address _whitelist, bool isWL) public onlyOwner {
        _isExcludedMaxTransactionAmount[_whitelist] = isWL;

        _isExcludedFromFees[_whitelist] = isWL;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function manualswap(uint256 amount) external {
        require(_msgSender() == marketingWallet);
        require(amount <= balanceOf(address(this)) && amount > 0, "Wrong amount");
        swapTokensForEth(amount);
    }

    function manualsend() external {
        bool success;
        (success,) = address(marketingWallet).call{value: address(this).balance}("");
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _marketingFee) external onlyOwner {
        buyTotalFees = _marketingFee;
    }

    function updateSellFees(uint256 _marketingFee) external onlyOwner {
        sellTotalFees = _marketingFee;
    }

    function updateFees(uint256 _buy, uint256 _sell) external onlyOwner {
        buyTotalFees = _buy;
        sellTotalFees = _sell;
    }

    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (limitsInEffect) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if ((launchedAt + blocks) >= block.number) {
                    // Starting Taxes
                    sellTotalFees = 60;
                    buyTotalFees = 30;
                }

                if (!tradingActive) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }

                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from]
                && !_isExcludedFromFees[to]
        ) {
            // Limit swaps per block
            if (blockSwaps[block.number] < 3) {
                swapping = true;

                swapBack();

                swapping = false;

                blockSwaps[block.number] = blockSwaps[block.number] + 1;
            }
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = (amount * buyTotalFees) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > maxSwapAmount) {
            contractBalance = maxSwapAmount;
        }

        // Halve the amount of liquidity tokens

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        uint256 totalETH = address(this).balance;

        (success,) = address(marketingWallet).call{value: totalETH}("");
    }
}