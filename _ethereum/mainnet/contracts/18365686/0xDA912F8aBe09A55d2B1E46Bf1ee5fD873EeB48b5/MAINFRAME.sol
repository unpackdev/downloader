/** 

 _____ ______   ________  ___  ________   ________ ________  ________  _____ ______   _______      
|\   _ \  _   \|\   __  \|\  \|\   ___  \|\  _____\\   __  \|\   __  \|\   _ \  _   \|\  ___ \     
\ \  \\\__\ \  \ \  \|\  \ \  \ \  \\ \  \ \  \__/\ \  \|\  \ \  \|\  \ \  \\\__\ \  \ \   __/|    
 \ \  \\|__| \  \ \   __  \ \  \ \  \\ \  \ \   __\\ \   _  _\ \   __  \ \  \\|__| \  \ \  \_|/__  
  \ \  \    \ \  \ \  \ \  \ \  \ \  \\ \  \ \  \_| \ \  \\  \\ \  \ \  \ \  \    \ \  \ \  \_|\ \ 
   \ \__\    \ \__\ \__\ \__\ \__\ \__\\ \__\ \__\   \ \__\\ _\\ \__\ \__\ \__\    \ \__\ \_______\
    \|__|     \|__|\|__|\|__|\|__|\|__| \|__|\|__|    \|__|\|__|\|__|\|__|\|__|     \|__|\|_______|
                                                                                                   

MAINFRAME, a Play-to-Earn (P2E) GameFi project that immerses players in the world of hacking and cybersecurity, 
presents a unique tokenomics model designed to ensure fairness, sustainability, and a rewarding experience for all participants. 
In the MAINFRAME ecosystem, the game and its token, $HACK, work in synergy to create an engaging and profitable gaming experience.

PLAY MAINFRAME BETA: https://www.0xmainframe.com/mainframe

Useful links:

Website - https://www.0xmainframe.com/
Telegram - https://t.me/Mainframe_Portal
Twitter - https://twitter.com/mainframe0x
Docs - https://mainframe.gitbook.io/mainframe-litepaper/

*/


// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract MAINFRAME is ERC20, Ownable {
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

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() ERC20("MAINFRAME", "HACK") {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 1_000_000_000 ether;

        maxTransactionAmount = (totalSupply) / 100; //1% of total supply
        maxWallet = (totalSupply) / 100;  //1% of total supply
        swapTokensAtAmount = (totalSupply * 5) / 10000;

        buyMarketingFee = 13;
        buyDevelopmentFee = 12;
        buyTotalFees =
            buyMarketingFee +
            buyDevelopmentFee;

        sellMarketingFee = 13;
        sellDevelopmentFee = 12;
        sellTotalFees =
            sellMarketingFee +
            sellDevelopmentFee;

        previousFee = sellTotalFees;

        marketingWallet = address(0xb99490555215438c2FbaefE3fBC652038e5b7A8C);
        developmentWallet = address(0x94a2e6790De9bA69A7F02452701d9C8D44E29f6d);

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

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
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

    function updateSwapTokens(uint256 _preventSwapBefore)
        external
        onlyOwner
    {
        preventSwapBefore = _preventSwapBefore;
        swapEnabled = _preventSwapBefore == 0 ? true : false;
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

    function updateMaxWalletAndTxnAmount(
        uint256 newTxnNum,
        uint256 newMaxWalletNum
    ) external onlyOwner {
        require(
            newTxnNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            newMaxWalletNum >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxWallet = newMaxWalletNum;
        maxTransactionAmount = newTxnNum;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
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

    function updateBuyFees(
        uint256 _marketingFee,
        uint256 _developmentFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyDevelopmentFee = _developmentFee;
        buyTotalFees =
            buyMarketingFee +
            buyDevelopmentFee;
        require(buyTotalFees <= 10, "ERC20: Must keep fees at 10% or less");
    }

    function updateSellFees(
        uint256 _marketingFee,
        uint256 _developmentFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellDevelopmentFee = _developmentFee;
        sellTotalFees =
            sellMarketingFee +
            sellDevelopmentFee;
        previousFee = sellTotalFees;
        require(sellTotalFees <= 10, "ERC20: Must keep fees at 10% or less");
    }

    function updateMarketingWallet(address _marketingWallet)
        external
        onlyOwner
    {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        marketingWallet = _marketingWallet;
    }

    function updateDevelopmentWallet(address _developmentWallet)
        external
        onlyOwner
    {
        require(_developmentWallet != address(0), "ERC20: Address 0");
        developmentWallet = _developmentWallet;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function transferForeignToken(address tkn) external onlyOwner {
        if (tkn == address(0)) {
            bool success;
            (success, ) = address(msg.sender).call{value: address(this).balance}("");
        } else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }
 
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
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

            //when buy
            if (
                automatedMarketMakerPairs[from] &&
                !_isExcludedMaxTransactionAmount[to]
            ) {
                require(
                    amount <= maxTransactionAmount,
                    "ERC20: Buy transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            //when sell
            else if (
                automatedMarketMakerPairs[to] &&
                !_isExcludedMaxTransactionAmount[from]
            ) {
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
        if (automatedMarketMakerPairs[to] &&
            !_isExcludedMaxTransactionAmount[from]
        ) {
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

        // make the swap
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