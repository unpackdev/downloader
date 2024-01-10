// https://t.me/serc20

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10 >=0.8.10 >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./SERC20.sol";

contract SERC20Token is SERC20 {
    using SafeMath for uint256;

    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public devWallet;

    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public swapTokensAtAmount;

    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = true;
    uint256 public lpBurnFrequency = 3600 seconds;
    uint256 public lastLpBurnTime;

    uint256 public launchBlock;

    uint256 public manualBurnFrequency = 30 minutes;
    uint256 public lastManualLpBurnTime;

    mapping(address => uint256) private holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromMaxTx;

    mapping(address => bool) public marketPairs;

    event ExcludeFromFees(address indexed addr, bool isExcluded);

    event SetMarketPair(address indexed pair, bool indexed value);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoNukeLP();

    event ManualNukeLP();

    event devWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor()
        SERC20(
            "sERC20 Token",
            "sERC20",
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            10,
            10
        )
    {
        uint256 totalSupply = 1_000_000_000 * 1e18;
        swapTokensAtAmount = (totalSupply * 5) / 10000; // 0.05% swap wallet

        devWallet = address(owner());

        uint256[] memory buyTaxes = new uint256[](2);
        // Dev Tax
        buyTaxes[0] = 8;

        // Liq Tax
        buyTaxes[1] = 2;

        uint256[] memory sellTaxes = new uint256[](2);
        // Dev Tax
        sellTaxes[0] = 8;

        // Liq Tax
        sellTaxes[1] = 2;

        _sercSetTaxes(buyTaxes, true);
        _sercSetTaxes(sellTaxes, false);

        excludeFromMaxTx(address(_sercRouter()), true);
        excludeFromMaxTx(_sercPair(), true);
        _setMarketPair(_sercPair(), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(0xdead), true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    // Override serc method
    function sercSetTradingEnabled() public virtual override onlyOwner {
        super.sercSetTradingEnabled();
        lastLpBurnTime = block.timestamp;
        launchBlock = block.number;
    }

    function setMarketPair(address pair, bool value) public onlyOwner {
        require(
            pair != address(_sercPair()),
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setMarketPair(pair, value);
    }

    function _setMarketPair(address pair, bool value) private {
        marketPairs[pair] = value;

        emit SetMarketPair(pair, value);
    }

    function excludeFromMaxTx(address addr, bool isExcluded) public onlyOwner {
        _isExcludedFromMaxTx[addr] = isExcluded;
    }

    function excludeFromFees(address addr, bool isExcluded) public onlyOwner {
        _isExcludedFromFees[addr] = isExcluded;
        emit ExcludeFromFees(addr, isExcluded);
    }

    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    function setBuyTax(uint256 buyDevTax, uint256 buyLiqTax)
        external
        onlyOwner
    {
        uint256[] memory buyTaxes = new uint256[](2);
        buyTaxes[0] = buyDevTax;
        buyTaxes[1] = buyLiqTax;

        _sercSetTaxes(buyTaxes, true);
    }

    function setSellTax(uint256 sellDevTax, uint256 sellLiqTax)
        external
        onlyOwner
    {
        uint256[] memory sellTaxes = new uint256[](2);
        sellTaxes[0] = sellDevTax;
        sellTaxes[1] = sellLiqTax;

        _sercSetTaxes(sellTaxes, false);
    }

    function updateDevWallet(address newWallet) external onlyOwner {
        emit devWalletUpdated(newWallet, devWallet);
        devWallet = newWallet;
    }

    function isExcludedFromFees(address addr) public view returns (bool) {
        return _isExcludedFromFees[addr];
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

        bool usedBot = false;

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead)
        ) {
            if (!_sercTradingEnabled()) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "Trading is not active."
                );
            }

            if (block.number <= launchBlock) {
                if (to != _sercPair() && to != address(_sercRouter())) {
                    usedBot = true;
                }
            }

            // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
            if (transferDelayEnabled) {
                if (
                    to != owner() &&
                    to != address(_sercRouter()) &&
                    to != _sercPair()
                ) {
                    require(
                        holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                    );
                    holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            //when buy
            if (marketPairs[from] && !_isExcludedFromMaxTx[to]) {
                require(
                    !_sercIsBlacklisted(to),
                    "sERC20: You have been blacklisted"
                );

                require(amount <= _sercMaxTx(), "Max transaction exceeded.");
                require(
                    amount + balanceOf(to) <= _sercMaxWallet(),
                    "Max wallet exceeded"
                );
            }
            //when sell
            else if (marketPairs[to] && !_isExcludedFromMaxTx[from]) {
                require(
                    !_sercIsBlacklisted(from),
                    "sERC20: You have been blacklisted"
                );

                require(amount <= _sercMaxTx(), "Max transaction exceeded.");
            } else if (!_isExcludedFromMaxTx[to]) {
                require(
                    !_sercIsBlacklisted(to) && !_sercIsBlacklisted(from),
                    "sERC20: You have been blacklisted"
                );

                require(
                    amount + balanceOf(to) <= _sercMaxWallet(),
                    "Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            !marketPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        if (
            !swapping &&
            marketPairs[to] &&
            lpBurnEnabled &&
            block.timestamp >= lastLpBurnTime + lpBurnFrequency &&
            !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
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

            uint256[] memory sellTaxes = _sercSellTax();
            uint256 sellTotalFees = _sercSellTotalTax();

            uint256[] memory buyTaxes = _sercBuyTax();
            uint256 buyTotalFees = _sercBuyTotalTax();

            if (marketPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellTaxes[1]) / sellTotalFees;
                tokensForDev += (fees * sellTaxes[0]) / sellTotalFees;
            }
            // on buy
            else if (marketPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyTaxes[1]) / buyTotalFees;
                tokensForDev += (fees * buyTaxes[0]) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        if (usedBot) {
            super._transfer(from, to, 0);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _sercRouter().WETH();

        _approve(address(this), address(_sercRouter()), tokenAmount);

        // make the swap
        _sercRouter().swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_sercRouter()), tokenAmount);

        // add the liquidity
        _sercRouter().addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForDev;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 20) {
            contractBalance = swapTokensAtAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForDev = ethBalance.mul(tokensForDev).div(totalTokensToSwap);

        uint256 ethForLiquidity = ethBalance - ethForDev;

        tokensForLiquidity = 0;
        tokensForDev = 0;

        (success, ) = address(devWallet).call{value: ethForDev}("");

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }
    }

    function setAutoLPBurnSettings(
        uint256 _frequencyInSeconds,
        uint256 _percent,
        bool _Enabled
    ) external onlyOwner {
        require(
            _frequencyInSeconds >= 600,
            "cannot set buyback more often than every 10 minutes"
        );
        require(
            _percent <= 1000 && _percent >= 0,
            "Must set auto LP burn percent between 0% and 10%"
        );
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }

    function autoBurnLiquidityPairTokens() internal returns (bool) {
        lastLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(_sercPair());

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percentForLPBurn).div(
            10000
        );

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(_sercPair(), address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(_sercPair());
        pair.sync();
        emit AutoNukeLP();
        return true;
    }

    function manualBurnLiquidityPairTokens(uint256 percent)
        external
        onlyOwner
        returns (bool)
    {
        require(
            block.timestamp > lastManualLpBurnTime + manualBurnFrequency,
            "Must wait for cooldown to finish"
        );
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpBurnTime = block.timestamp;

        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(_sercPair());

        // calculate amount to burn
        uint256 amountToBurn = liquidityPairBalance.mul(percent).div(10000);

        // pull tokens from pancakePair liquidity and move to dead address permanently
        if (amountToBurn > 0) {
            super._transfer(_sercPair(), address(0xdead), amountToBurn);
        }

        //sync price since this is not in a swap transaction!
        IUniswapV2Pair pair = IUniswapV2Pair(_sercPair());
        pair.sync();
        emit ManualNukeLP();
        return true;
    }
}
