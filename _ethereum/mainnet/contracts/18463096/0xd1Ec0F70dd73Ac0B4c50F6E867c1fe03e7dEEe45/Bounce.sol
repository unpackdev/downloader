// SPDX-License-Identifier: MIT

/*
The Bounce Game. 

The most interactive, play to win blockchain game on Ethereum.

X: https://x.com/bouncegame_eth

Website: https://thebouncegame.io

Telegram: https://t.me/officialbounceportal

*/

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Uniswap.sol";
import "./SafeMath.sol";

contract BOUNCE is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private constant _name = unicode"The Bounce Game";
    string private constant _symbol = unicode"BOUNCE";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 4200000 * 10**_decimals;
    uint256 public _maxTxAmount = _totalSupply / 50;
    uint256 public _maxWalletSize = _totalSupply / 25;

    // tax
    uint256 public _tax = 30;
    uint16 private _taxRatePrize = 0;
    uint16 private _taxRateMarket = 0;
    uint16 private _taxRateDev = 0;
    uint16 private _taxRateRevShare = 0;
    // wallet
    address public devWallet;
    address public marketingWallet;
    address public revShareWallet;
    // Uniswap
    IUniswapV2Router02 public router;
    address public pair;
    // swap
    bool private swapping = false;
    bool public swapEnabled = true;
    uint256 public swapTokensAtAmount;
    // prize pool
    uint256 private prizePoolETH = 0;
    bool public isTradingOpen;
    //
    uint8 public taxStatus = 0;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    /////////////
    //  Events //
    /////////////
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MaxLimitAmountUpdated(uint256 _maxTxAmount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event RevShareWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor(address _devWallet, address _marketWallet) {
        setDevWallet(_devWallet);
        setMarketingWallet(_marketWallet);

        // setSwapTokensAtAmount(12600);
        setSwapTokensAtAmount(10000);

        // set rev wallet
        revShareWallet = address(0x714BA105Ab416E9040A87aCaB140aE8327115957);

        IUniswapV2Router02 _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        router = _router;

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );
        pair = _pair;

        _setAutomatedMarketMakerPair(_pair, true);

        excludeFromMaxWallet(address(_pair), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(_router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);

        _balances[_msgSender()] = _totalSupply;
    }

    ////////////
    // IERC20 //
    ////////////

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    ///////////////////////
    // Exclude functions //
    ///////////////////////

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value);
        automatedMarketMakerPairs[newPair] = value;

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    // ////////////////////////
    // // Transfer Functions //
    // ////////////////////////

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "Invalid address");
        require(to != address(0), "Invalid address");

        if (from == pair && to != address(router) && !_isExcludedFromFees[to]) {
            require(isTradingOpen, "trading is not open");
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(
                balanceOf(to) + amount <= _maxWalletSize,
                "Exceeds the maxWalletSize."
            );
        }

        if (to != pair && !_isExcludedFromFees[to]) {
            require(
                balanceOf(to) + amount <= _maxWalletSize,
                "Exceeds the maxWalletSize."
            );
        }

        //
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (!swapping && to == pair && swapEnabled && canSwap) {
            swapTax(swapTokensAtAmount);
        }

        bool takeFee = !swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            !automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to]
        ) {
            takeFee = false;
        }

        uint256 taxAmount = 0;
        if (takeFee) {
            taxAmount = amount.mul(_tax).div(100);

            if (taxAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(
                    taxAmount
                );
                emit Transfer(from, address(this), taxAmount);
            }
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function swapTax(uint256 tokenAmount) private {
        uint256 ethBalanceBeforeSwap = address(this).balance;
        swapTokensForEth(tokenAmount);
        uint256 amountReceived = address(this).balance.sub(
            ethBalanceBeforeSwap
        );

        uint256 amountPrizePool = amountReceived.mul(_taxRatePrize).div(100);
        prizePoolETH = prizePoolETH + amountPrizePool;

        uint256 amountMarketWallet = amountReceived.mul(_taxRateMarket).div(
            100
        );
        sendETH2(marketingWallet, amountMarketWallet);

        uint256 amountDevWallet = amountReceived.mul(_taxRateDev).div(100);
        sendETH2(devWallet, amountDevWallet);

        uint256 amountRevShareWallet = amountReceived.mul(_taxRateRevShare).div(
            100
        );
        sendETH2(revShareWallet, amountRevShareWallet);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    ////////////////////////
    //   Owner Functions  //
    ////////////////////////

    function batchTransfer(
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) public onlyOwner {
        require(_addresses.length == _amounts.length, "Length not match");

        for (uint256 i = 0; i < _addresses.length; i++) {
            bool sent = transfer(_addresses[i], _amounts[i] * 10**_decimals);
            require(sent, "Token transfer failed");
        }
    }

    function setTax(uint256 tax, uint16 taxStage) public onlyOwner {
        _tax = tax;
        if (taxStage == 0) {
            _taxRatePrize = 0;
            _taxRateMarket = 100;
            _taxRateDev = 0;
            _taxRateRevShare = 0;
        } else if (taxStage == 1) {
            _taxRatePrize = 20;
            _taxRateMarket = 40;
            _taxRateDev = 10;
            _taxRateRevShare = 30;
        } else if (taxStage == 2) {
            _taxRatePrize = 25;
            _taxRateMarket = 25;
            _taxRateDev = 25;
            _taxRateRevShare = 25;
        }
    }

    function openTrading() public onlyOwner {
        // Verify that the transaction is open
        require(!isTradingOpen, "trading is already open");
        // Enable transaction
        isTradingOpen = true;
    }

    function removeLimits() public onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        emit MaxLimitAmountUpdated(_totalSupply);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function setMarketingWallet(address newWallet) public onlyOwner {
        marketingWallet = newWallet;
    }

    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function updateRevShareWallet(address newRevShareWallet)
        external
        onlyOwner
    {
        emit RevShareWalletUpdated(newRevShareWallet, revShareWallet);
        revShareWallet = newRevShareWallet;
    }

    function sendETH(address _to, uint256 _ethAmount) private {
        payable(_to).transfer(_ethAmount);
    }

    function sendETH2(address _to, uint256 _ethAmount) private {
        if (_ethAmount > 0) {
            (bool success, ) = payable(_to).call{value: _ethAmount}("");
            require(success); //Failed to send ETH to wallet
        }
    }

    function sendETHToAddress(address _to) public onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(_to).call{value: ETHbalance}("");
        require(success);
    }

    function sendLPToAddress(address _to) public onlyOwner {
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(_to, lpBalance);
    }

    function balanceOfPrize() public view onlyOwner returns (uint256) {
        return prizePoolETH;
    }

    function sendPrize(
        address[] calldata _accounts,
        uint256[] calldata _amounts
    ) public onlyOwner returns (bool) {
        require(
            _accounts.length > 0 && _accounts.length == _amounts.length,
            "Length not match"
        );
        require(prizePoolETH > 0, "Prize pool is empty");

        //
        uint256 totalPrize = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalPrize += _amounts[i];
        }
        require(prizePoolETH >= totalPrize, "Prize pool is not enough");

        // send
        for (uint256 i = 0; i < _accounts.length; i++) {
            sendETH(_accounts[i], _amounts[i]);
        }
        prizePoolETH = prizePoolETH - totalPrize;

        return true;
    }

    function setTotalPrize() public onlyOwner {
        prizePoolETH = address(this).balance;
    }

    receive() external payable {}
}
