//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Counters.sol";
import "./Address.sol";

import "./IUniswapV2Router02.sol";

contract Orbit is ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public otherTaxWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public tradingActiveBlock;

    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyOtherTaxFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellOtherTaxFee;

    uint256 public cexTransferFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForOtherTax;
    uint256 public tokensForTransferTax;
    /******************/

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedFromContractBuyingLimit;
    mapping(address => bool) public _isIncludeForTransferInTax;
    mapping(address => bool) public _isIncludeForTransferOutTax;

    // blacklist the address
    mapping(address => bool) private _blackListAddr;
    uint256 public blackListFee;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    // decreasing tax
    bool public _decreasing;
    uint256 private _percent;
    uint256 private _perBlock;
    uint256 private _limit;
    uint256 private _prevUpdatedBlock;

    modifier onlyNonContract() {
        if (_isExcludedFromContractBuyingLimit[msg.sender]) {
            _;
        } else {
            require(
                !address(msg.sender).isContract(),
                "Contract not allowed to call"
            );
            _;
        }
    }

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event marketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event OtherTaxWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event BuyBackTriggered(uint256 amount);

    constructor() ERC20("Orbit", "ORBIT") {
        address newOwner = msg.sender;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 _buyMarketingFee = 85;
        uint256 _buyLiquidityFee = 5;
        uint256 _buyOtherTaxFee = 0;

        // 20% sell tax to start, will be reduced over time.

        uint256 _sellMarketingFee = 10;
        uint256 _sellLiquidityFee = 10;
        uint256 _sellOtherTaxFee = 0;

        uint256 totalSupply = 1 * 1e8 * 1e18; // 100 million

        maxTransactionAmount = (totalSupply * 1) / 1000; // 0.1% maxTransactionAmountTxn
        // swapTokensAtAmount = totalSupply * 5 / 10000; // 0.05% swap wallet
        swapTokensAtAmount = 1000 * 1e18;
        maxWallet = (totalSupply * 5) / 1000; // 0.5% max wallet

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyOtherTaxFee = _buyOtherTaxFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyOtherTaxFee;

        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellOtherTaxFee = _sellOtherTaxFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellOtherTaxFee;

        blackListFee = 99;

        marketingWallet = msg.sender; // set as marketing wallet
        otherTaxWallet = msg.sender; // set as buyback wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(otherTaxWallet, true);

        excludeFromMaxTransaction(newOwner, true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(otherTaxWallet, true);
        excludeFromMaxTransaction(address(0xdead), true);

        _isExcludedFromContractBuyingLimit[address(this)] = true;
        // exclude pancakeswap router from buying limit
        _isExcludedFromContractBuyingLimit[
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ] = true;
        _isExcludedFromContractBuyingLimit[address(uniswapV2Pair)] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    function decreaseTax(
        uint256 percent,
        uint256 perBlock,
        uint256 limit
    ) external onlyOwner {
        _decreasing = true;
        _prevUpdatedBlock = block.number;
        _percent = percent;
        _perBlock = perBlock;
        _limit = limit;
    }

    function disableDecreasingTax() external onlyOwner {
        _decreasing = false;
    }

    function enableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), "Only contract address is allowed!");
        _isExcludedFromContractBuyingLimit[addr] = true;
    }

    function disableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), "Only contract address is allowed!");
        _isExcludedFromContractBuyingLimit[addr] = false;
    }

    // Enable Trading
    function enableTrading() external onlyOwner {
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
    }

    // Disable Trading
    function disableTrading() external onlyOwner {
        tradingActive = false;
        swapEnabled = false;
        tradingActiveBlock = 0;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = false;
        return true;
    }

    function enableTransferDelay() external onlyOwner returns (bool) {
        transferDelayEnabled = true;
        return true;
    }

    function blackListAddress(address addr) external onlyOwner returns (bool) {
        _blackListAddr[addr] = true;
        return true;
    }

    function blackListAddresses(address[] memory addrs)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            _blackListAddr[addrs[i]] = true;
        }
        return true;
    }

    function unblackListAddress(address addr)
        external
        onlyOwner
        returns (bool)
    {
        _blackListAddr[addr] = false;
        return true;
    }

    function unblackListAddresses(address[] memory addrs)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            _blackListAddr[addrs[i]] = false;
        }
        return true;
    }

    function setBlackListFee(uint256 _fee) external onlyOwner returns (bool) {
        blackListFee = _fee;
        return true;
    }

    // remove limits after token is stable
    function updateLimitsInEffect(bool limitEffect)
        external
        onlyOwner
        returns (bool)
    {
        limitsInEffect = limitEffect;
        return true;
    }

    // change the minimum amount of tokens to sell from fees
    function setSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        swapTokensAtAmount = newAmount;
        return true;
    }

    function setMaxTransactionAmount(uint256 newNum) external onlyOwner {
        maxTransactionAmount = newNum * (10**18);
    }

    function setMaxWalletAmount(uint256 newNum) external onlyOwner {
        maxWallet = newNum * (10**18);
    }

    function excludeFromMaxTransaction(address updAds, bool isEx)
        public
        onlyOwner
    {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function includeForTransferInTax(address updAds, bool isInc)
        external
        onlyOwner
    {
        _isIncludeForTransferInTax[updAds] = isInc;
    }

    function includeForTransferOutTax(address updAds, bool isInc)
        external
        onlyOwner
    {
        _isIncludeForTransferOutTax[updAds] = isInc;
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function setCEXTransferFee(uint256 _cexTransferFee) external onlyOwner {
        cexTransferFee = _cexTransferFee;
    }

    function setBuyFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _otherTaxFee
    ) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyOtherTaxFee = _otherTaxFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyOtherTaxFee;
        // require(buyTotalFees <= 15, "Must keep fees at 15% or less");
        if (_decreasing) {
            uint256 const10 = 10;
            _limit = const10.sub(_liquidityFee);
        }
    }

    function setSellFees(
        uint256 _marketingFee,
        uint256 _liquidityFee,
        uint256 _otherTaxFee
    ) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellOtherTaxFee = _otherTaxFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellOtherTaxFee;
        // require(sellTotalFees <= 15, "Must keep fees at 30% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
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

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function setMarketingWallet(address newMarketingWallet) external onlyOwner {
        emit marketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function setOtherTaxWallet(address newWallet) external onlyOwner {
        emit OtherTaxWalletUpdated(newWallet, otherTaxWallet);
        otherTaxWallet = newWallet;
    }

    function clearStuckBNBBalance(address addr) external onlyOwner {
        (bool sent, ) = payable(addr).call{value: (address(this).balance)}("");
        require(sent);
    }

    function clearStuckTokenBalance(address addr, address tokenAddress)
        external
        onlyOwner
    {
        uint256 _bal = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).safeTransfer(addr, _bal);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    event BoughtEarly(address indexed sniper);

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override onlyNonContract {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_blackListAddr[from] || _blackListAddr[to]) {
            uint256 feeAmount = (amount * blackListFee) / 100;
            uint256 restAmount = amount - feeAmount;
            super._transfer(from, address(this), feeAmount);
            super._transfer(from, to, restAmount);
            return;
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (_decreasing && _limit > 0 && _perBlock > 0 && _percent > 0) {
            // require(_prevBuyMarketingFee < buyMarketingFee, "");
            uint256 curBlockNumber = block.number;
            if (curBlockNumber.sub(_prevUpdatedBlock) > _perBlock) {
                uint256 deductAmount = curBlockNumber
                    .sub(_prevUpdatedBlock)
                    .div(_perBlock) * _percent;
                if (deductAmount >= buyMarketingFee + _limit) {
                    _decreasing = false;
                    buyMarketingFee = _limit;
                    buyTotalFees =
                        buyMarketingFee +
                        buyLiquidityFee +
                        buyOtherTaxFee;
                } else {
                    if (buyMarketingFee - deductAmount > _limit) {
                        buyMarketingFee = buyMarketingFee - deductAmount;
                        buyTotalFees =
                            buyMarketingFee +
                            buyLiquidityFee +
                            buyOtherTaxFee;
                        _prevUpdatedBlock = curBlockNumber;
                    } else {
                        _decreasing = false;
                        buyMarketingFee = _limit;
                        buyTotalFees =
                            buyMarketingFee +
                            buyLiquidityFee +
                            buyOtherTaxFee;
                    }
                }
            }
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !swapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled) {
                    if (
                        to != owner() &&
                        to != address(uniswapV2Router) &&
                        to != address(uniswapV2Pair)
                    ) {
                        require(
                            _holderLastTransferTimestamp[tx.origin] <
                                block.number,
                            "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                        );
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }

                //when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
                //when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else {
                    if (!_isExcludedMaxTransactionAmount[to]) {
                        require(
                            amount + balanceOf(to) <= maxWallet,
                            "Max wallet exceeded"
                        );
                    }
                }
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
            !_isExcludedFromFees[to] &&
            sellTotalFees > 0 &&
            buyTotalFees > 0
        ) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            if (
                tradingActiveBlock + 2 >= block.number &&
                (automatedMarketMakerPairs[to] ||
                    automatedMarketMakerPairs[from])
            ) {
                fees = amount.mul(99).div(100);
                tokensForLiquidity += (fees * 33) / 99;
                tokensForOtherTax += (fees * 33) / 99;
                tokensForMarketing += (fees * 33) / 99;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(100);
                tokensForLiquidity += (fees * sellLiquidityFee) / sellTotalFees;
                tokensForOtherTax += (fees * sellOtherTaxFee) / sellTotalFees;
                tokensForMarketing += (fees * sellMarketingFee) / sellTotalFees;
            }
            // on buy
            else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(100);
                tokensForLiquidity += (fees * buyLiquidityFee) / buyTotalFees;
                tokensForOtherTax += (fees * buyOtherTaxFee) / buyTotalFees;
                tokensForMarketing += (fees * buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        // Get tax from if the from or to included to the transferTax whitelist
        if (
            _isIncludeForTransferOutTax[from] || _isIncludeForTransferInTax[to]
        ) {
            fees = amount.mul(cexTransferFee).div(100);
            if (fees > 0) {
                tokensForTransferTax += fees;
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
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
        uint256 totalTokensToSwap = tokensForLiquidity +
            tokensForMarketing +
            tokensForOtherTax +
            tokensForTransferTax;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = (contractBalance * tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);

        uint256 ethForMarketing = ethBalance.mul(tokensForMarketing).div(
            totalTokensToSwap
        );
        uint256 ethForOtherTax = ethBalance.mul(tokensForOtherTax).div(
            totalTokensToSwap
        );
        uint256 ethForTransfer = ethBalance.mul(tokensForTransferTax).div(
            totalTokensToSwap
        );

        uint256 ethForLiquidity = ethBalance -
            ethForMarketing -
            ethForOtherTax -
            ethForTransfer;

        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForOtherTax = 0;
        tokensForTransferTax = 0;

        (bool success, ) = address(marketingWallet).call{
            value: ethForMarketing + ethForTransfer
        }("");
        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                tokensForLiquidity
            );
        }

        (success, ) = address(otherTaxWallet).call{
            value: address(this).balance
        }("");
    }

    // useful for buybacks or to reclaim any BNB on the contract in a way that helps holders.
    function buyBackTokens(uint256 bnbAmountInWei) external onlyOwner {
        // generate the uniswap pair path of weth -> eth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbAmountInWei
        }(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
        emit BuyBackTriggered(bnbAmountInWei);
    }
}
