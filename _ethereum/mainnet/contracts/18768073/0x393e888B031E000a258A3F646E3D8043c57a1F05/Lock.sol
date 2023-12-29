//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Stakify is Ownable, IERC20 {
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Stakify";
    string constant _symbol = "SIFY";
    uint8 constant _decimals = 18;

    uint256 _totalSupply; // One hundred billions

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isAuthorized;
    mapping(address => bool) isMaxWalletExcluded;
    mapping(address => bool) isMaxTxExcluded;

    address public treasuryWallet;

    // Fees
    uint256 public buyLiquidityFee;
    uint256 public buyTreasuryFee;
    uint256 public buyBurnFee;
    uint256 public buyStakeFee;
    uint256 public buyTotalFee;

    uint256 public sellLiquidityFee;
    uint256 public sellTreasuryFee;
    uint256 public sellStakeFee;
    uint256 public sellBurnFee;

    uint256 public sellTotalFee;

    bool public isRepellentEnabled;

    uint256 public repellentSellAutoBurnFee;
    uint256 public repellentSellLiquidityFee;
    uint256 public repellentSellTreasuryFee;
    uint256 public repellentSellStakeFee;
    uint256 public repellentSellTotalFee;

    uint256 public repellentBuyAutoBurnFee;
    uint256 public repellentBuyLiquidityFee;
    uint256 public repellentBuyTreasuryFee;
    uint256 public repellentBuyStakeFee;
    uint256 public repellentBuyTotalFee;

    address public stakingWallet;

    uint256 public launchtAt;

    event RepellentFeeActivated(uint256 activatedAmount);
    event RepellentFeeDisabled(uint256 disabledAmount);

    address BUSD;

    enum LPLevels {
        Level1,
        Level2,
        Level3,
        Level4,
        Level5
    }

    LPLevels public currentLpLevel;
    bool public isRepellentFee;

    uint256 public lastLPCheckedAt;
    uint256 public lastLPAmount;
    uint256 public lpCheckFrequency;

    struct LPRange {
        uint256 minLimit;
        uint256 maxLimit;
        uint256 dropLimit;
        uint256 recoverLimit;
    }

    mapping(LPLevels => LPRange) public lpRanges;

    uint256 public repellentFeeActivatedAt;
    uint256 public repellentFeeActivatedAmount;
    uint256 public repellentFeeRecoverAmount;

    uint256 public lastRepellentFeeActivatedAt;
    uint256 public lastRepellentFeeRecoveredAt;

    IUniswapV2Router02 public router;

    address public pair;

    bool public getTransferFees;

    uint256 public swapThreshold; // 0.001% of supply
    uint256 public maxTreansaction;
    uint256 public maxWallet;

    bool public contractSwapEnabled;
    bool public isTradeEnabled;
    bool inContractSwap;
    modifier swapping() {
        inContractSwap = true;
        _;
        inContractSwap = false;
    }

    event SetIsFeeExempt(address holder, bool status);
    event AddAuthorizedWallet(address holder, bool status);
    event SetDoContractSwap(bool status);
    event DoContractSwap(uint256 amount, uint256 time);

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    constructor() {
        _totalSupply = 244 * 10 ** 6 * (10 ** _decimals);

        buyLiquidityFee = 1;
        buyTreasuryFee = 2;
        buyBurnFee = 1;
        buyStakeFee = 1;
        buyTotalFee = 5;

        sellLiquidityFee = 1;
        sellTreasuryFee = 22;
        sellBurnFee = 1;
        sellStakeFee = 1;
        sellTotalFee = 25;

        repellentSellAutoBurnFee = 15;
        repellentSellLiquidityFee = 5;
        repellentSellTreasuryFee = 10;
        repellentSellTotalFee = 30;

        repellentBuyAutoBurnFee = 0;
        repellentBuyLiquidityFee = 0;
        repellentBuyTreasuryFee = 0;
        repellentBuyTotalFee = 0;

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        _allowances[address(this)][address(router)] = type(uint256).max;

        treasuryWallet = 0xdAb6280d5a87c10250F454EE3AD3b3b0C1A274C0;

        BUSD = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

        lpCheckFrequency = 24 hours;
        getTransferFees = false;
        isRepellentEnabled = true;

        swapThreshold = (_totalSupply * 1) / 10000; // 0.001% of supply
        maxTreansaction = (_totalSupply * 2) / 100;
        maxWallet = (_totalSupply * 2) / 100;

        contractSwapEnabled = true;
        isTradeEnabled = false;

        address newOwner = 0x64Ab7F64187AF212007A3EE9fdF990101DE4Bc16;

        isFeeExempt[newOwner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasuryWallet] = true;

        isAuthorized[newOwner] = true;
        isAuthorized[address(this)] = true;
        isAuthorized[ZERO] = true;
        isAuthorized[DEAD] = true;
        isAuthorized[treasuryWallet] = true;

        isMaxWalletExcluded[msg.sender] = true;
        isMaxTxExcluded[msg.sender] = true;

        isMaxWalletExcluded[ZERO] = true;
        isMaxTxExcluded[ZERO] = true;

        isMaxWalletExcluded[DEAD] = true;
        isMaxTxExcluded[DEAD] = true;

        lpRanges[LPLevels.Level1].minLimit = 0;
        lpRanges[LPLevels.Level1].maxLimit = 100000 * 10 ** 6;
        lpRanges[LPLevels.Level1].dropLimit = 1000;
        lpRanges[LPLevels.Level1].recoverLimit = 2000;

        lpRanges[LPLevels.Level2].minLimit = 100000 * 10 ** 6;
        lpRanges[LPLevels.Level2].maxLimit = 200000 * 10 ** 6;
        lpRanges[LPLevels.Level2].dropLimit = 750;
        lpRanges[LPLevels.Level2].recoverLimit = 1500;

        lpRanges[LPLevels.Level3].minLimit = 200000 * 10 ** 6;
        lpRanges[LPLevels.Level3].maxLimit = 500000 * 10 ** 6;
        lpRanges[LPLevels.Level3].dropLimit = 500;
        lpRanges[LPLevels.Level3].recoverLimit = 1000;

        lpRanges[LPLevels.Level4].minLimit = 500000 * 10 ** 6;
        lpRanges[LPLevels.Level4].maxLimit = 1000000 * 10 ** 6;
        lpRanges[LPLevels.Level4].dropLimit = 250;
        lpRanges[LPLevels.Level4].recoverLimit = 500;

        lpRanges[LPLevels.Level5].minLimit = 1000000 * 10 ** 6;
        lpRanges[LPLevels.Level5].maxLimit = 600000 * 10 ** 6;
        lpRanges[LPLevels.Level5].dropLimit = 100;
        lpRanges[LPLevels.Level5].recoverLimit = 200;

        _balances[newOwner] = _totalSupply;
        emit Transfer(address(0), newOwner, _totalSupply);

        transferOwnership(newOwner);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(
                _allowances[sender][msg.sender] >= amount,
                "Insufficient Allowance"
            );
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (!isTradeEnabled) require(isAuthorized[sender], "Trading disabled");
        if (inContractSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        if (!isMaxTxExcluded[sender])
            require(amount <= maxTreansaction, "Max transaction exceeded");

        if (!isMaxWalletExcluded[recipient] && recipient != pair) {
            require(
                (_balances[recipient] + amount) <= maxWallet,
                "Max wallet exceeded"
            );
        }

        if (
            (lastLPCheckedAt + lpCheckFrequency) < block.timestamp &&
            !isRepellentFee &&
            isTradeEnabled
        ) {
            uint256 lpBnbBalance = IERC20(router.WETH()).balanceOf(
                address(pair)
            );
            lastLPAmount = getBnbPrice(lpBnbBalance);
            lastLPCheckedAt = block.timestamp;
        }

        if (isTradeEnabled) calculateLPStatus();

        if (shouldDoContractSwap()) {
            doContractSwap();
        }

        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldDoContractSwap() internal view returns (bool) {
        return (msg.sender != pair &&
            !inContractSwap &&
            contractSwapEnabled &&
            sellTotalFee > 0 &&
            _balances[address(this)] >= swapThreshold);
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
        uint256 feeToken;
        uint256 burnTokens;
        uint256 stakeTokens;

        if (isRepellentFee && isRepellentEnabled) {
            if (recipient == pair && repellentSellTotalFee > 0) {
                feeToken = (amount * repellentSellTotalFee) / 100;

                // get burn tokens
                if (repellentSellAutoBurnFee > 0)
                    burnTokens =
                        (feeToken * repellentSellAutoBurnFee) /
                        repellentSellTotalFee;

                // get sell tokens
                if (repellentSellStakeFee > 0)
                    stakeTokens =
                        (feeToken * repellentSellStakeFee) /
                        repellentSellTotalFee;
            } else if (repellentBuyTotalFee > 0) {
                feeToken = (amount * repellentBuyTotalFee) / 100;
                if (repellentBuyAutoBurnFee > 0)
                    burnTokens =
                        (feeToken * repellentBuyAutoBurnFee) /
                        repellentBuyTotalFee;

                if (repellentBuyStakeFee > 0)
                    stakeTokens =
                        (feeToken * repellentBuyStakeFee) /
                        repellentSellTotalFee;
            }
        } else {
            if (recipient == pair && sellTotalFee > 0) {
                feeToken = (amount * sellTotalFee) / 100;
                if (sellBurnFee > 0)
                    burnTokens = (feeToken * sellBurnFee) / sellTotalFee;

                if (sellStakeFee > 0)
                    stakeTokens = (feeToken * sellStakeFee) / sellTotalFee;
            } else if (buyTotalFee > 0) {
                feeToken = (amount * buyTotalFee) / 100;
                if (buyBurnFee > 0)
                    burnTokens = (feeToken * buyBurnFee) / buyTotalFee;

                if (buyStakeFee > 0)
                    stakeTokens = (feeToken * buyStakeFee) / buyTotalFee;
            }
        }
        if (burnTokens > 0) {
            _balances[DEAD] = _balances[DEAD] + burnTokens;
            emit Transfer(sender, DEAD, burnTokens);
        }
        if (stakeTokens > 0) {
            _balances[stakingWallet] = _balances[stakingWallet] + stakeTokens;
            emit Transfer(sender, stakingWallet, stakeTokens);
        }

        _balances[address(this)] =
            _balances[address(this)] +
            (feeToken - (burnTokens + stakeTokens));
        emit Transfer(
            sender,
            address(this),
            (feeToken - (burnTokens + stakeTokens))
        );

        return (amount - feeToken);
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient Balance");
        _balances[sender] = _balances[sender] - amount;

        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(
        address sender,
        address to
    ) internal view returns (bool) {
        if (!getTransferFees) {
            if (sender != pair && to != pair) return false;
        }
        if (isFeeExempt[sender] || isFeeExempt[to]) {
            return false;
        } else {
            return true;
        }
    }

    function isFeeExcluded(address _wallet) public view returns (bool) {
        return isFeeExempt[_wallet];
    }

    function doContractSwap() internal swapping {
        uint256 contractTokenBalance = _balances[address(this)];

        uint256 tokensToLp = (contractTokenBalance * sellLiquidityFee) /
            sellTotalFee;

        uint256 marketingFee = contractTokenBalance - tokensToLp;

        if (marketingFee > 0) {
            swapTokensForEth(marketingFee);

            uint256 swappedTokens = address(this).balance;

            if (swappedTokens > 0)
                payable(treasuryWallet).transfer(swappedTokens);
        }

        if (tokensToLp > 0) swapAndLiquify(tokensToLp);
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the contract balance into halves
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit AutoLiquify(newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;

        emit SetIsFeeExempt(holder, exempt);
    }

    function setDoContractSwap(bool _enabled) external onlyOwner {
        contractSwapEnabled = _enabled;

        emit SetDoContractSwap(_enabled);
    }

    function changeTreasuryWallet(address _wallet) external onlyOwner {
        treasuryWallet = _wallet;
    }

    function changeBuyFees(
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _stakeFee
    ) external onlyOwner {
        buyLiquidityFee = _liquidityFee;
        buyTreasuryFee = _treasuryFee;
        buyBurnFee = _burnFee;
        buyStakeFee = _stakeFee;

        buyTotalFee = _liquidityFee + _treasuryFee + _burnFee + _stakeFee;

        require(buyTotalFee <= 10, "Total fees can not greater than 10%");
    }

    function changeSellFees(
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _burnFee,
        uint256 _stakeFee
    ) external onlyOwner {
        sellLiquidityFee = _liquidityFee;
        sellTreasuryFee = _treasuryFee;
        sellBurnFee = _burnFee;
        sellStakeFee = _stakeFee;

        sellTotalFee = _liquidityFee + _treasuryFee + _burnFee + _stakeFee;

        if (isTradeEnabled && (launchtAt + 24 hours) < block.timestamp)
            require(sellTotalFee <= 10, "Total fees can not greater than 10%");
    }

    function enableTrading() external onlyOwner {
        isTradeEnabled = true;
        launchtAt = block.timestamp;
    }

    function setAuthorizedWallets(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isAuthorized[_wallet] = _status;
    }

    function rescueEth() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No enough ETH to transfer");

        payable(msg.sender).transfer(balance);
    }

    function changeGetFeesOnTransfer(bool _status) external onlyOwner {
        getTransferFees = _status;
    }

    function changeLpCheckFrequency(uint256 _hours) external onlyOwner {
        lpCheckFrequency = _hours;
    }

    function changeRepellentSellFees(
        uint256 _autoBurnFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _stakeFee
    ) external onlyOwner {
        repellentSellAutoBurnFee = _autoBurnFee;
        repellentSellLiquidityFee = _liquidityFee;
        repellentSellTreasuryFee = _treasuryFee;
        repellentSellStakeFee = _stakeFee;

        repellentSellTotalFee =
            _autoBurnFee +
            _liquidityFee +
            _treasuryFee +
            _stakeFee;

        require(repellentSellTotalFee <= 30, "Fees can not be grater than 30%");
    }

    function changeRepellentBuyFees(
        uint256 _autoBurnFee,
        uint256 _liquidityFee,
        uint256 _treasuryFee,
        uint256 _stakeFee
    ) external onlyOwner {
        repellentBuyAutoBurnFee = _autoBurnFee;
        repellentBuyLiquidityFee = _liquidityFee;
        repellentBuyTreasuryFee = _treasuryFee;
        repellentBuyStakeFee = _stakeFee;

        repellentBuyTotalFee =
            _autoBurnFee +
            _liquidityFee +
            _treasuryFee +
            _stakeFee;

        require(repellentSellTotalFee <= 20, "Fees can not be grater than 20%");
    }

    function setLpRange(
        LPLevels _level,
        uint256 _min,
        uint256 _max,
        uint256 _drop,
        uint256 _recover
    ) external onlyOwner {
        LPRange storage currentRange = lpRanges[_level];

        currentRange.minLimit = _min;
        currentRange.maxLimit = _max;
        currentRange.dropLimit = _drop;
        currentRange.recoverLimit = _recover;
    }

    function calculateLPStatus() internal {
        uint256 lpBnbBalance = IERC20(router.WETH()).balanceOf(address(pair));
        uint256 lpBalance = getBnbPrice(lpBnbBalance);

        if (
            lpBalance >= lpRanges[LPLevels.Level1].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level1].maxLimit
        ) currentLpLevel = LPLevels.Level1;

        if (
            lpBalance >= lpRanges[LPLevels.Level2].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level2].maxLimit
        ) currentLpLevel = LPLevels.Level2;

        if (
            lpBalance >= lpRanges[LPLevels.Level3].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level3].maxLimit
        ) currentLpLevel = LPLevels.Level3;

        if (
            lpBalance >= lpRanges[LPLevels.Level4].minLimit &&
            lpBalance <= lpRanges[LPLevels.Level4].maxLimit
        ) currentLpLevel = LPLevels.Level4;

        if (lpBalance >= lpRanges[LPLevels.Level5].minLimit)
            currentLpLevel = LPLevels.Level5;

        if (lastLPAmount > lpBalance && !isRepellentFee) {
            uint256 lpDifference = lastLPAmount - lpBalance;

            uint256 differencePercentage = ((lpDifference * 10000) /
                lastLPAmount);

            if (differencePercentage > lpRanges[currentLpLevel].dropLimit) {
                isRepellentFee = true;
                repellentFeeActivatedAt = block.timestamp;
                lastRepellentFeeActivatedAt = block.timestamp;
                repellentFeeActivatedAmount = lpBalance;
                repellentFeeRecoverAmount =
                    lpBalance +
                    ((lpBalance * lpRanges[currentLpLevel].recoverLimit) /
                        10000);

                emit RepellentFeeActivated(lpBalance);
            }
        }
        if (isRepellentFee && lpBalance > repellentFeeRecoverAmount) {
            isRepellentFee = false;
            repellentFeeActivatedAt = 0;
            repellentFeeActivatedAmount = 0;
            repellentFeeRecoverAmount = 0;

            lastRepellentFeeRecoveredAt = block.timestamp;

            lastLPAmount = lpBalance;

            emit RepellentFeeDisabled(lpBalance);
        }
    }

    function getBnbPrice(uint256 _amount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = BUSD;

        uint256[] memory amounts = router.getAmountsOut(_amount, path);

        return amounts[1];
    }

    function changeMaxWallet(uint256 _amount) external onlyOwner {
        require(
            _amount >= ((_totalSupply * 2) / 100),
            "Max wallet can not less than 2%"
        );

        maxWallet = _amount;
    }

    function changeMaxTx(uint256 _amount) external onlyOwner {
        require(
            _amount >= ((_totalSupply * 1) / 100),
            "Max wallet can not less than 1%"
        );

        maxTreansaction = _amount;
    }

    function maxWalletExclude(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isMaxWalletExcluded[_wallet] = _status;
    }

    function maxTxExclude(address _wallet, bool _status) external onlyOwner {
        isMaxTxExcluded[_wallet] = _status;
    }

    function toggleReppelent(bool _status) external onlyOwner {
        isRepellentEnabled = _status;
    }

    function changeStakeAddress(address _stakePool) external onlyOwner {
        stakingWallet = _stakePool;
    }
}
