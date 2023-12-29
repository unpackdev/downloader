
// SPDX-License-Identifier: MIT

/*
Telegram: t.me/PinkPepe_PIPE_ERC20
Twitter: https://twitter.com/PinkPepe_PIPE_ERC20
Website: incoming
*/

pragma solidity ^0.8.1;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract PiPe is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    address payable public taxWallet;

    bool private swapping;

    string private constant _name = unicode"Pink Pepe";
    string private constant _symbol = unicode"PiPe";
    uint256 tTotal = 420_000_000_000_000 * 1e18;

    uint256 public _maxTxAmount;
    uint256 public swapTokensAtAmount;
    uint256 public _maxWallet;

    bool public _tradeLimit = true;
    bool public tradingOpen = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyTaxFee = 0;
    uint256 public buyLiquidityFee = 18;

    uint256 public sellTotalFees;
    uint256 public sellTaxFee = 0;
    uint256 public sellLiquidityFee = 25;

    uint256 public tokensForTax;
    uint256 public tokensForLiquidity;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20(_name,_symbol) {
        taxWallet = payable(_msgSender());
        _maxTxAmount = (tTotal * 2) / 100;
        _maxWallet = (tTotal * 2) / 100;
        swapTokensAtAmount = (tTotal * 1) / 10000; 
        buyTotalFees = buyTaxFee + buyLiquidityFee;
        sellTotalFees = sellTaxFee + sellLiquidityFee;
        excludeFromFees(_msgSender(), true);
        excludeFromFees(address(this), true);
        excludeFromMaxTransaction(_msgSender(), true);
        excludeFromMaxTransaction(address(this), true);
        _mint(_msgSender(), tTotal);
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen,"Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),tTotal,0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    function removeLimits() external onlyOwner returns (bool) {
        _tradeLimit = false;
        return true;
    }

    function reduceFees(uint256 _buyMktFee, uint256 _buyLqFee, uint256 _sellMktFee, uint256 _sellLqFee) external onlyOwner {
        buyTaxFee = _buyMktFee;
        buyLiquidityFee = _buyLqFee;
        sellTaxFee = _sellMktFee;
        sellLiquidityFee = _sellLqFee;
        buyTotalFees = buyTaxFee + buyLiquidityFee;
        sellTotalFees = sellTaxFee + sellLiquidityFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,address(0xdead),block.timestamp);
    }

    function swapBack() private {
        bool success;
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTax;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }
        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForEth(amountToSwapForETH);
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(tokensForTax).div(
            totalTokensToSwap
        );
        uint256 ethForLiquidity = ethBalance - ethForMarketing;
        tokensForLiquidity = 0;
        tokensForTax = 0;
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        ethBalance=address(this).balance;
        if(ethBalance>50000000000000000){
            (success, ) = address(taxWallet).call{
                value: address(this).balance
            }("");
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if (_tradeLimit) {
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !swapping) {
                if (!tradingOpen) {
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to],"Trading is not active.");
                }

                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= _maxTxAmount,"Buy transfer amount exceeds the _maxTxAmount.");
                    require(amount + balanceOf(to) <= _maxWallet,"Max wallet exceeded");
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(amount <= _maxTxAmount, "Sell transfer amount exceeds the _maxTxAmount.");
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= _maxWallet,"Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }
        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForTax += (fees * sellTaxFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForTax += (fees * buyTaxFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    receive() external payable {}
}