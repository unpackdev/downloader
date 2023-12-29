// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./Governable.sol";

contract Chad is ERC20, Governable {
    IUniswapV2Router02 public uniswapV2Router;

    //address data-sets
    address public unibotAddress = address(0xf819d9Cb1c2A819Fd991781A822dE3ca8607c3C9);
    address public teamWallet = address(0x76Fa3D6bf5560231C96f66b7c0623565B3511a6A);
    address public prizePoolWallet = address(0xEe79ce770607e84484651509ACae81E99a8679ee);
    address public unibotBuyWallet = address(0x76Fa3D6bf5560231C96f66b7c0623565B3511a6A);
    address public uniswapV2Pair;

    //bool data-sets
    bool public isLimitActive = true;
    bool public isTradingOpen = false;
    bool public swapEnabled = false;
    bool public isAutoBuyUnibotActive = false;
    bool private swapping;
    bool public isInitialized;

    //int data-sets
    uint256 public _buyUnibotBuyFee = 10; // 1%
    uint256 public _buyPrizePoolFee = 20; // 2%
    uint256 public _buyLpFee = 5; // 0.5%
    uint256 public _buyTeamFee = 5; // 0.5%
    uint256 public buyTotalFees = _buyLpFee + _buyTeamFee + _buyUnibotBuyFee + _buyPrizePoolFee;

    uint256 public _sellUnibotBuyFee = 10; // 1%
    uint256 public _sellPrizePoolFee = 20; // 2%
    uint256 public _sellLpFee = 5; // 0.5%
    uint256 public _sellTeamFee = 5; // 0.5%
    uint256 public sellTotalFees = _sellLpFee + _sellTeamFee + _sellUnibotBuyFee + _sellPrizePoolFee;

    uint256 public _unibotBuyTokenShare;
    uint256 public _prizeTokenShare;
    uint256 public _lpTokenShare;
    uint256 public _teamTokenShare;

    uint256 public swapTokensAtAmount;

    uint256 public competitionStart;

    //mapping data-sets
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event CollectedTax(uint256 ethBalance, uint256 ethForLiquiity, uint256 ethForPrizePool);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);

    constructor() ERC20("CHAD", "CHAD") {
        uint256 totalSupply = 1_000_000 * 1e18;
        _mint(msg.sender, totalSupply);
    }

    // dataset
    function initContract() external onlyGov {
        require(!isInitialized, "Contract already initialised");

        //DEX data-sets
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        swapTokensAtAmount = (this.totalSupply() * 5) / 10000;
        competitionStart = 1702911600; // 10am EST 18th DEC first competition

        excludeFromFees(this.gov(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        isInitialized = true;
    }

    function launchChad() external onlyGov {
        isTradingOpen = true;
        swapEnabled = true;
    }

    function setIsLimitActive(bool _isActive) external onlyGov {
        isLimitActive = _isActive;
    }

    function setIsTradingOpen(bool _isOpen) external onlyGov {
        isTradingOpen = _isOpen;
    }

    function setSwapEnabled(bool _swapEnabled) external onlyGov {
        swapEnabled = _swapEnabled;
    }

    function setIsAutoBuyUnibotActive(bool _isActive) external onlyGov {
        isAutoBuyUnibotActive = _isActive;
    }

    function setUniswapRouterv2(address _uniswapV2Router) public onlyGov {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    function setUnibotAddress(address _unibotAddress) public onlyGov {
        unibotAddress = _unibotAddress;
    }

    function setCompetitionStart(uint256 _competitionStart) public onlyGov {
        competitionStart = _competitionStart;
    }

    function setSwapTokensAtAmount(uint256 _amount) external onlyGov {
        require(_amount <= (totalSupply() * 5) / 1000, "Swap limit cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = _amount;
    }

    function setBuyFees(uint256 _lpFee, uint256 _unibotFee, uint256 _prizePoolFee, uint256 _teamFee) external onlyGov {
        _buyPrizePoolFee = _prizePoolFee;
        _buyUnibotBuyFee = _unibotFee;
        _buyLpFee = _lpFee;
        _buyTeamFee = _teamFee;
        buyTotalFees = _buyLpFee + _buyTeamFee + _buyPrizePoolFee + _buyUnibotBuyFee;
        require(buyTotalFees <= 40, "Buy fee max should 4%");
    }

    function setSellFees(uint256 _lpFee, uint256 _unibotFee, uint256 _prizePoolFee, uint256 _teamFee)
        external
        onlyGov
    {
        _sellPrizePoolFee = _prizePoolFee;
        _sellUnibotBuyFee = _unibotFee;
        _sellLpFee = _lpFee;
        _sellTeamFee = _teamFee;
        sellTotalFees = _sellLpFee + _sellTeamFee + _sellPrizePoolFee + _sellUnibotBuyFee;
        require(sellTotalFees <= 40, "Sell Max must be 4%");
    }

    function excludeFromFees(address account, bool excluded) public onlyGov {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyGov {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function setTeamWallet(address _account) external onlyGov {
        teamWallet = _account;
    }

    function setUnibotBuyWallet(address _account) external onlyGov {
        unibotBuyWallet = _account;
    }

    function setPrizePoolWallet(address _account) external onlyGov {
        prizePoolWallet = _account;
    }

    function blacklist(address account) public onlyGov {
        blacklisted[account] = true;
    }

    function unblacklist(address account) public onlyGov {
        blacklisted[account] = false;
    }

    function withdrawEth(address _to) external onlyGov {
        (bool success,) = address(_to).call{value: address(this).balance}("");
        require(success);
    }

    function withdrawTaxesEarly(address _to) external onlyGov {
        uint256 totalTaxes = taxedTokens();
        super._transfer(address(this), _to, totalTaxes);

        _lpTokenShare = 0;
        _unibotBuyTokenShare = 0;
        _teamTokenShare = 0;
        _prizeTokenShare = 0;
    }

    function taxedTokens() public view returns (uint256) {
        return (_lpTokenShare + _unibotBuyTokenShare + _teamTokenShare + _prizeTokenShare);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklisted[from], "Sender blacklisted");
        require(!blacklisted[to], "Receiver blacklisted");

        if (amount == 0) {
            super._transfer(from, to, 0);
        }

        if (isLimitActive) {
            if (from != this.gov() && to != this.gov() && to != address(0) && to != address(0xdead) && !swapping) {
                if (!isTradingOpen) {
                    require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading is not active.");
                }

                if (block.timestamp < competitionStart) {
                    require(isExcludedFromFees[from] || isExcludedFromFees[to], "Trading has not started.");
                }
            }
        }

        uint256 contractTokenBalance = this.balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        if (
            canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !isExcludedFromFees[from]
                && !isExcludedFromFees[to]
        ) {
            swapping = true;
            _swapNow();
            swapping = false;
        }

        bool takeFee = true;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = 0;
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount * sellTotalFees / 1000;
                _lpTokenShare += (fees * _sellLpFee) / sellTotalFees;
                _prizeTokenShare += (fees * _sellPrizePoolFee) / sellTotalFees;
                _teamTokenShare += (fees * _sellTeamFee) / sellTotalFees;
                _unibotBuyTokenShare += (fees * _sellUnibotBuyFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 1000;
                _lpTokenShare += (fees * _buyLpFee) / buyTotalFees;
                _prizeTokenShare += (fees * _buyPrizePoolFee) / buyTotalFees;
                _teamTokenShare += (fees * _buyTeamFee) / buyTotalFees;
                _unibotBuyTokenShare += (fees * _buyUnibotBuyFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
                amount -= fees;
            }
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, address(this), block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, teamWallet, block.timestamp);
    }

    function _unibotAutoBuy(uint256 ethAmount) private {
        if (ethAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = unibotAddress;
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
                0, path, teamWallet, block.timestamp
            );
        }
    }

    function _swapNow() private {
        uint256 contractBalance = this.balanceOf(address(this));
        uint256 totalTokensToSwap = taxedTokens();
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        uint256 liquidityTokens = (contractBalance * _lpTokenShare) / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 chadLp = _lpTokenShare / 2;

        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 ethForTeam = ethBalance * _teamTokenShare / (totalTokensToSwap - chadLp);
        uint256 ethForPrizePool = ethBalance * _prizeTokenShare / (totalTokensToSwap - chadLp);
        uint256 ethForBuyback = ethBalance * _unibotBuyTokenShare / (totalTokensToSwap - chadLp);

        uint256 ethForLiquidity = ethBalance - ethForTeam - ethForPrizePool - ethForBuyback;

        emit CollectedTax(ethBalance, ethForLiquidity, ethForPrizePool);

        (success,) = address(teamWallet).call{value: ethForTeam}("");
        (success,) = address(prizePoolWallet).call{value: ethForPrizePool}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(liquidityTokens, ethForLiquidity, _lpTokenShare);
        }

        if (isAutoBuyUnibotActive) {
            _unibotAutoBuy(ethForBuyback);
        } else {
            (success,) = address(unibotBuyWallet).call{value: ethForBuyback}("");
        }

        _lpTokenShare = 0;
        _prizeTokenShare = 0;
        _unibotBuyTokenShare = 0;
        _teamTokenShare = 0;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    receive() external payable {}
}
