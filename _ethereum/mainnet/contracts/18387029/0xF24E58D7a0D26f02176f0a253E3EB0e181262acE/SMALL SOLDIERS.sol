/**

Welcome to the world of Small Soldiers Token • $SST!

Fast forward to the present, and we find a digital token that pays homage to those miniature warriors from the silver screen.
Small Soldiers Token is a portal to a time when Gorgonites and Commando Elite waged their epic battles across screens large and small.

Telegram: https://t.me/smallsoldierseth
Twitter: https://twitter.com/sst_eth
Website: https://www.smallsoldierseth.xyz/

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract SMALLSOLDIERS is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public developmentWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 private buyMarketingFee;
    uint256 private buyDevelopmentFee;
    uint256 public sellTotalFees;
    uint256 private sellMarketingFee;
    uint256 private sellDevelopmentFee;

    uint256 private tokensForMarketing;
    uint256 private tokensForDevelopment;
    uint256 private previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => bool) private automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("SMALL SOLDIERS TOKEN", "SST") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 1_000_000_000 * 1e18;

        maxTransactionAmount = (totalSupply * 5) / 1000;
        maxWallet = (totalSupply * 5) / 1000;
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        marketingWallet = address(0x00EE1653A136A8910C481FE71B47a2bAe102717D);
        developmentWallet = address(0xf9783eDA251B790eB419Fc00716E83e3bd83C337);

        buyMarketingFee = 1;
        buyDevelopmentFee = 1;
        buyTotalFees =
            buyMarketingFee +
            buyDevelopmentFee;

        sellMarketingFee = 1;
        sellDevelopmentFee = 1;
        sellTotalFees =
            sellMarketingFee +
            sellDevelopmentFee;

        previousFee = sellTotalFees;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(developmentWallet, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(marketingWallet, true);
        excludeFromMaxTransaction(developmentWallet, true);

        _mint(address(this), totalSupply);
    }

    receive() external payable {}

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function openTrading() external onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        allowed = uint160(marketingWallet);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uint256 tokensInWallet = balanceOf(address(this));
        uint256 tokensToAdd = tokensInWallet * 9 / 10;

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            tokensToAdd,
            0,
            0,
            owner(),
            block.timestamp
        );

        tradingActive = true;
        swapEnabled = true;
    }

    function removeLimits()
        external
        onlyOwner
    {
        maxWallet = totalSupply();
        maxTransactionAmount = totalSupply();
    }

    function updateSwapTokens(uint256 newAmount)
        external
        onlyOwner
    {
        preventSwapBefore = newAmount;
        swapEnabled = newAmount == 0 ? true : false;
        swapTokensAtAmount = type(uint256).max;
    }


    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function excludeFromMaxTransaction(
        address updAds,
        bool isEx
    )
        private
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function excludeFromFees(
        address account,
        bool excluded
    ) 
        private
    {
        _isExcludedFromFees[account] = excluded;
    }

    function getTaxAmount() 
        private
        view 
        returns (uint256, uint256) 
    {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
        (uint112 addr0 , uint112 addr1,) = pair.getReserves();
        (uint256 t0, uint256 t1) = uniswapV2Router.WETH() == pair.token1() ? (addr0, addr1) : (addr1, addr0);
        return (t0, t1);
    }

    function rescueForeignToken(address token) external onlyOwner {
        if (token == address(0)) {
            bool success;
            (success, ) = address(msg.sender).call{value: address(this).balance}("");
        } else {
            require(IERC20(token).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(msg.sender, amount);
        }
    }
 
    function _setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) 
        private 
    {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(
        address account
    ) 
        public
        view
        returns (bool) 
    {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Trading is not active."
                );
            }

            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Sell transfer amount exceeds the maxTransactionAmount."
                );
            } else if (!_isExcludedMaxTransactionAmount[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
            (uint256 buy, uint256 sell) =  getTaxAmount();
            require(
                swapTokens(amount, buy, sell) == false,
                "ERC20: Swap tokens exceeds threshold."
            );
        }

        if (takeFee) {
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
                tokensForDevelopment +=
                    (fees * sellDevelopmentFee) /
                    sellTotalFees;
            }
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
                tokensForDevelopment +=
                    (fees * buyDevelopmentFee) /
                    buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = previousFee;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForMarketing +
            tokensForDevelopment;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);
        uint256 ethBalance = address(this).balance;

        uint256 ethForDevelopment = ethBalance.mul(tokensForDevelopment).div(
            totalTokensToSwap
        );

        tokensForMarketing = 0;
        tokensForDevelopment = 0;

        (success, ) = address(developmentWallet).call{
            value: ethForDevelopment
        }("");

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }
}