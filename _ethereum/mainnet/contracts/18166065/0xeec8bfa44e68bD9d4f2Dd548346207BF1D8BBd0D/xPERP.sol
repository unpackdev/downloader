// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//  xPERP Token
//   ____  _____ ____  ____
//   __  _|  _ \| ____|  _ \|  _ \
//   \ \/ / |_) |  _| | |_) | |_) |
//    >  <|  __/| |___|  _ <|  __/
//   /_/\_\_|   |_____|_| \_\_|
// Go long or short with leverage on @friendtech keys via Telegram
// =====================================
// https://twitter.com/xperptech
// https://xperp.tech
// =====================================
// - Fair Launch: 99% of the token supply was added to liquidity at launch.
// - Partnership: 1% has been sold to Handz of Gods.
// - Supply: 1M tokens, fully circulating and non-dilutive.
// - Tax: 5% tax on xperp traded (1% to LP, 2% to revenue share, 2% to team and operating expenses).
// - Revenue Sharing: 30% of trading revenue goes to holders. xperp earns 2% of all trading volume.
// - Eligibility: Holders of xperp tokens are entitled to revenue sharing.

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Pausable.sol";
import "./TokenTimelock.sol";

contract xPERP is ERC20, Ownable, Pausable, ReentrancyGuard {

    // 1 Million is totalsuppy
    uint256 public constant oneMillion = 1_000_000 * 1 ether;
    // precision mitigation value, 100x100
    uint256 public constant hundredPercent = 10_000;

    // 1% of total supply, max tranfer amount possible
    uint256 public walletBalanceLimit = 10_000 * 1 ether;

    // Taxation
    uint256 public totalTax = 500;
    uint256 public liquidityPairTax = 100;
    uint256 public teamWalletTax = 200;
    bool public isTaxActive = true;

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    // address of the uniswap pair
    address public uniswapV2Pair;

    // address of the revenue distribution bot
    address public revenueDistributionBot;

    // team wallet
    address payable public teamWallet;

    // switched on post launch
    bool public isTradingEnabled = false;

    // revenue sharing tax collected, completely distributed among token holders
    uint256 public liquidityPairTaxCollectedNotYetInjectedXPERP;

    // total swap tax collected, completely distributed among token holders, for analytical purposes only
    uint256 public swapTaxCollectedTotalXPERP;

    // revenue sharing tax collected, completely distributed among token holders, for analytical purposes only
    uint256 public tradingRevenueDistributedTotalETH;

    // Revenue sharing distribution info, 1 is the first epoch.
    struct EpochInfo {
        // Snapshot time
        uint256 epochTimestamp;
        // Snapshot supply
        uint256 epochTotalSupply;
        // ETH collected for rewards for re-investors
        uint256 epochRevenueFromSwapTaxCollectedXPERP;
        // Same in ETH
        uint256 epochSwapRevenueETH;
        // Injected 30% revenue from trading
        uint256 epochTradingRevenueETH;
        // Used to calculate holder balances at the time of snapshot
        mapping(address => uint256) depositedInEpoch;
        mapping(address => uint256) withdrawnInEpoch;
    }

    // Epochs array, each epoch contains the snapshot info
    EpochInfo[] public epochs;

    // Claimed Epochs
    mapping(address => uint256) public lastClaimedEpochs;

    // ========== Events ==========
    event TradingOnUniSwapEnabled();
    event TradingOnUniSwapDisabled();
    event Snapshot(uint256 epoch, uint256 totalSupply, uint256 swapTaxCollected, uint256 tradingRevenueCollected);
    event SwappedToEth(uint256 amount, uint256 ethAmount);
    event SwappedToXperp(uint256 amount, uint256 ethAmount);
    event Claimed(address indexed user, uint256 amount);
    event LiquidityAdded(uint256 amountToken, uint256 amountETH, uint256 liquidity);
    event ReceivedEther(address indexed from, uint256 amount);
    event TaxChanged(uint256 tax, uint256 teamWalletTax, uint256 liquidityPairTax);
    event TaxActiveChanged(bool isActive);

    // ========== Modifiers ==========


    modifier botOrOwner() {
        require(msg.sender == revenueDistributionBot || msg.sender == owner(), "Not authorized");
        _;
    }

    // ========== ERC20 ==========

    constructor(address payable _teamWallet) ERC20("xperp", "xperp") {
        require(_teamWallet != address(0), "Invalid team wallet");
        teamWallet = _teamWallet;
        _mint(msg.sender, oneMillion);
    }

    // ========== Configuration ==========

    function init() external onlyOwner {
        // creating the uniswap pair
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
        // approving uniswap router to spend xperp on behalf of the contract
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        // initializing epochs, 1 is the first epoch.
        epochs.push();
    }

    function setRevenueDistributionBot(address _revenueDistributionBot) external onlyOwner {
        require(_revenueDistributionBot != address(0), "Invalid bot address");
        revenueDistributionBot = _revenueDistributionBot;
    }

    function setTax(uint256 _tax, uint256 _teamWalletTax, uint256 _liquidityPairTax) external onlyOwner {
        require(_tax >= 0 && _tax <= 500 && _teamWalletTax >= 0 && _teamWalletTax <= 500, "Invalid tax");
        totalTax = _tax;
        teamWalletTax = _teamWalletTax;
        liquidityPairTax = _liquidityPairTax;
        emit TaxChanged(_tax, _teamWalletTax, _liquidityPairTax);
    }

    function setTaxActive(bool _isTaxActive) external onlyOwner {
        isTaxActive = _isTaxActive;
        emit TaxActiveChanged(_isTaxActive);
    }

    function setWalletBalanceLimit(uint256 _walletBalanceLimit) external onlyOwner {
        require(_walletBalanceLimit >= 0 && _walletBalanceLimit <= oneMillion, "Invalid wallet balance limit");
        walletBalanceLimit = _walletBalanceLimit;
    }

    function updateTeamWallet(address payable _teamWallet) external onlyOwner {
        require(_teamWallet != address(0), "Invalid team wallet");
        teamWallet = _teamWallet;
    }

    function EnableTradingOnUniSwap() external onlyOwner {
        isTradingEnabled = true;
        emit TradingOnUniSwapEnabled();
    }

    function DisableTradingOnUniSwap() external onlyOwner {
        isTradingEnabled = false;
        emit TradingOnUniSwapDisabled();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ========== ERC20 Overrides ==========
    /// @dev overriden ERC20 transfer to tax on transfers to and from the uniswap pair, xperp is swapped to ETH and prepared for snapshot distribution
    function _transfer(address from, address to, uint256 amount) internal override {
        bool isTradingTransfer =
            (from == uniswapV2Pair || to == uniswapV2Pair) &&
            msg.sender != address(uniswapV2Router) &&
            from != address(this) && to != address(this) &&
            from != owner() && to != owner() &&
            from != revenueDistributionBot && to != revenueDistributionBot;

        require(isTradingEnabled || !isTradingTransfer, "Trading is not enabled yet");

        // if trading is enabled, only allow transfers to and from the uniswap pair
        if (epochs.length > 0) {
            uint256 currentEpoch = epochs.length - 1;
            epochs[currentEpoch].depositedInEpoch[to] += amount;
            epochs[currentEpoch].withdrawnInEpoch[from] += amount;
        }

        uint256 amountAfterTax = amount;
        // calculate 5% swap tax
        // owner() is an exception to fund the liquidity pair and revenueDistributionBot as well to fund the revenue distribution to holders
        if (isTaxActive && isTradingTransfer) {
            require(isTradingEnabled, "Trading is not enabled yet");
            address holder = from == uniswapV2Pair ? to : from;
            require(balanceOf(holder) + amount <= walletBalanceLimit, "Holding amount exceeds maximum allowed tokens.");
            // 5% total tax on xperp traded (1% to LP, 2% to revenue share, 2% to team and operating expenses).
            // we get
            uint256 taxAmountXPERP = (amount * totalTax) / hundredPercent;
            super._transfer(from, address(this), taxAmountXPERP);
            amountAfterTax -= taxAmountXPERP;
            swapTaxCollectedTotalXPERP += taxAmountXPERP;

            // 1% to LP, counting and keeping on the contract in xperp
            uint256 lpShareXPERP = (amount * liquidityPairTax) / hundredPercent;
            liquidityPairTaxCollectedNotYetInjectedXPERP += lpShareXPERP;
        }
        super._transfer(from, to, amountAfterTax);
    }

    // ========== Revenue Sharing ==========

    // Function called by the revenue distribution bot to snapshot the state
    function snapshot() external payable botOrOwner nonReentrant {
        epochs.push();
        EpochInfo storage epoch = epochs[epochs.length - 1];
        epoch.epochTimestamp = block.timestamp;
        uint256 _circulatingSupply = circulatingSupply();
        require(balanceOf(address(this)) >= liquidityPairTaxCollectedNotYetInjectedXPERP, "balance less than liquidity allocated");
        uint256 xperpToSwap = balanceOf(address(this)) - liquidityPairTaxCollectedNotYetInjectedXPERP;
        uint256 totalTaxETH = swapXPERPToETH(xperpToSwap);
        // 2% to team and operating expenses distributed immediately
        uint256 teamWalletTaxAmountETH = (totalTaxETH * teamWalletTax) / (totalTax - liquidityPairTax);
        teamWallet.transfer(teamWalletTaxAmountETH);
        // the rest (2%) in ETH is kept on the contract for revenue share distribution
        // amount_4% * 2%/4% = amount_2%
        epoch.epochTotalSupply = _circulatingSupply;
        epoch.epochTradingRevenueETH = msg.value;
        epoch.epochRevenueFromSwapTaxCollectedXPERP = xperpToSwap;
        epoch.epochSwapRevenueETH = totalTaxETH;
        emit Snapshot(epochs.length, _circulatingSupply, totalTaxETH, msg.value);
    }

    function claimAll() public nonReentrant {
        require(epochs.length > 0, "No epochs yet");
        uint256 holderShare = 0;
        for (uint256 i = lastClaimedEpochs[msg.sender]; i < epochs.length; i++)
            holderShare += getClaimable(i);
        lastClaimedEpochs[msg.sender] = epochs.length - 1;
        require(address(this).balance >= holderShare, "Insufficient contract balance");
        payable(msg.sender).transfer(holderShare);
        emit Claimed(msg.sender, holderShare);
    }

    // ========== Liquidity Injection ==========
    /// @dev this function uses 1% LP tax token collected from swaps, swaps tokens for ETH and adds this to liquidity pair.
    /// @dev There's also an option to transfer additional tokens and ETH to the contract, which will be used for liquidity injection
    /// @dev This function can be called by anyone
    function injectLiquidity(uint256 tokenAmount) external botOrOwner nonReentrant payable {
        require(balanceOf(address(this)) >= liquidityPairTaxCollectedNotYetInjectedXPERP, "Not enough tokens");
        if (tokenAmount > 0)
            transfer(address(this), tokenAmount);

        // Tokens eligible for injection
        uint256 amountTokenToUse = (liquidityPairTaxCollectedNotYetInjectedXPERP + tokenAmount) / 2;

        //Swap TokenForEth
        uint256 ethAmount = swapXPERPToETH(amountTokenToUse);

        // Add liquidity using all the received tokens and remaining ETH
        (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            amountTokenToUse,
            0,
            ethAmount,
            msg.sender,
            block.timestamp
        );
        liquidityPairTaxCollectedNotYetInjectedXPERP = 0;
        emit LiquidityAdded(amountToken, amountETH, liquidity);
    }

    // ========== Internal Functions ==========

    function swapXPERPToETH(uint256 _amount) internal returns (uint256) {
        if (_amount == 0) return 0;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uint256 initialETHBalance = address(this).balance;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 finalETHBalance = address(this).balance;
        uint256 ETHReceived = finalETHBalance - initialETHBalance;
        emit SwappedToEth(_amount, ETHReceived);
        return ETHReceived;
    }

    // ========== Rescue Functions ==========

    function rescueETH(uint256 _weiAmount) external {
        payable(owner()).transfer(_weiAmount);
    }

    function rescueERC20(address _tokenAdd, uint256 _amount) external {
        IERC20(_tokenAdd).transfer(owner(), _amount);
    }

    // ========== Fallbacks ==========


    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
    // ========== View functions ==========

    function getBalanceForEpoch(uint256 _epoch) public view returns (uint256) {
        if (_epoch >= epochs.length) return 0;
        uint256 currentBalance = balanceOf(msg.sender);
        if (epochs.length > 1) {
            uint256 e = epochs.length - 1;
            while (true) {
                currentBalance += epochs[e].withdrawnInEpoch[msg.sender];
                currentBalance -= epochs[e].depositedInEpoch[msg.sender];
                if (e == _epoch || e == 0) {
                    break;
                }
                e--;
            }
        }
        return currentBalance;
    }

    function getClaimable(uint256 _epoch) public view returns (uint256) {
        if (epochs.length == 0 || epochs.length <= _epoch) return 0;
        EpochInfo storage epoch = epochs[_epoch];
        if (_epoch <= lastClaimedEpochs[msg.sender] || epoch.epochTotalSupply == 0)
            return 0;
        else
            return (getBalanceForEpoch(_epoch) * (epoch.epochSwapRevenueETH + epoch.epochTradingRevenueETH)) / epoch.epochTotalSupply;
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(address(this)) - balanceOf(uniswapV2Pair) - balanceOf(owner());
    }
}
