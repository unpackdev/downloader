// Twitter: https://twitter.com/LPshareerc 
// Website: https://lpshares.tech
// Telegram: https://t.me/LpShares


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./DividendTracker.sol";
import "./IStaking.sol";

contract LPS is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;

    bool private swapping;
    bool public claimStatus;
    bool public tradingEnabled;

    DividendTracker public dividendTracker;

    address public marketingWallet;
    IStaking public staking;

    uint256 public swapTokensAtAmount = 300000 * 1e18;
    uint256 public maxBuyAmount = 2000000 * 1e18;
    uint256 public maxSellAmount = 2000000 * 1e18;
    uint256 public maxWallet = 2000000 * 1e18;

    struct Fees {
        uint256 liquidity;
        uint256 marketing;
        uint256 staking;
    }

    Fees public fees = Fees(3, 2, 1);

    uint256 public totalFees = 6;

    uint256 private _initialTax = 20;
    uint256 private _reduceTaxAt = 20;
    uint256 private _buyCount = 0;
    uint256 private _sellCount = 0;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    constructor(address _stakingPool) ERC20("LPShares", "LPS") {
        marketingWallet = _msgSender();

        router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        pair = IFactory(router.factory()).createPair(
            address(this),
            router.WETH()
        );

        dividendTracker = new DividendTracker();

        staking = IStaking(_stakingPool);
        staking.init(address(this), pair);

        _setAutomatedMarketMakerPair(pair, true);

        dividendTracker.updateLP_Token(pair);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(_stakingPool, true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(router), true);

        setExcludeFromMaxWallet(address(pair), true);
        setExcludeFromMaxWallet(address(this), true);
        setExcludeFromMaxWallet(address(router), true);
        setExcludeFromMaxWallet(_stakingPool, true);
        setExcludeFromMaxWallet(address(dividendTracker), true);

        setExcludeFromFees(owner(), true);
        setExcludeFromFees(address(this), true);
        setExcludeFromFees(_stakingPool, true);
        setExcludeFromFees(address(dividendTracker), true);

        _mint(owner(), 100000000 * (10 ** 18));

        _approve(address(this), address(router), type(uint256).max);
    }

    receive() external payable {}

    function claimLP() external {
        require(claimStatus, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    function enableClaimLP(bool _status) external onlyOwner {
        claimStatus = _status;
    }

    function setMaxAmount(
        uint256 _maxWallet,
        uint256 _maxBuy,
        uint256 _maxSell
    ) external onlyOwner {
        require(_maxWallet >= 1000000, "Cannot set maxWallet lower than 1%");
        require(_maxBuy >= 1000000, "Can't set maxbuy lower than 1% ");
        require(_maxSell >= 500000, "Can't set maxsell lower than 0.5% ");
        maxWallet = _maxWallet * 10 ** 18;
        maxBuyAmount = _maxBuy * 10 ** 18;
        maxSellAmount = _maxSell * 10 ** 18;
    }

    function updateStakingPool(address _stakingPool) external onlyOwner {
        staking = IStaking(_stakingPool);
    }

    function setExcludeFromMaxWallet(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function setExcludeFromFees(
        address account,
        bool excluded
    ) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;
    }

    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function startTrading() external onlyOwner {
        require(!tradingEnabled, "Already enabled");
        tradingEnabled = true;
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {
        return dividendTracker.getAccount(account);
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
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding maxSellAmount"
                );
                _sellCount++;
            } else if (automatedMarketMakerPairs[from]) {
                require(
                    amount <= maxBuyAmount,
                    "You are exceeding maxBuyAmount"
                );
                _buyCount++;
            }
            if (!_isExcludedFromMaxWallet[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            swapAndLiquify(swapTokensAtAmount);

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to]) {
                feeAmt =
                    (amount *
                        (_sellCount > _reduceTaxAt ? totalFees : _initialTax)) /
                    100;
            } else if (automatedMarketMakerPairs[from]) {
                feeAmt =
                    (amount *
                        (_buyCount > _reduceTaxAt ? totalFees : _initialTax)) /
                    100;
            }

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwapForLiq = ((tokens * fees.liquidity) / totalFees) / 2;
        uint256 tokensToAddLiquidityWith = ((tokens * fees.liquidity) /
            totalFees) / 2;
        uint256 toSwapForDev = (tokens * fees.marketing) / totalFees;
        uint256 toStakingPool = (tokens * fees.staking) / totalFees;

        super._transfer(address(this), address(staking), toStakingPool);

        staking.updateReward(toStakingPool);

        swapTokensForETH(toSwapForLiq);

        uint256 currentbalance = address(this).balance;

        if (currentbalance > 0) {
            addLiquidity(tokensToAddLiquidityWith, currentbalance);
        }

        swapTokensForETH(toSwapForDev);

        uint256 devAmt = address(this).balance;

        if (devAmt > 0) {
            (bool success, ) = payable(marketingWallet).call{value: devAmt}("");
            require(success, "Failed to send ETH to dev wallet");
        }
    }

    function distributionDiv(uint256 amount) public onlyOwner {
        IERC20(pair).transferFrom(
            _msgSender(),
            address(dividendTracker),
            amount
        );
        dividendTracker.distributeLPDividends(amount);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        (, , uint256 liquidity) = router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(dividendTracker),
            block.timestamp
        );

        if (liquidity > 0) {
            dividendTracker.distributeLPDividends(liquidity);
        }
    }
}
