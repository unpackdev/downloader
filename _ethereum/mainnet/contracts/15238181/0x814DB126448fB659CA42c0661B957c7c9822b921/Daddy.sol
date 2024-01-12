// SPDX-License-Identifier: MIT

/***************************************************************************************************************************
    
    ...........................................................................,..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    .......................................................................,,......,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ...........................................................#,(.*(,..,.,(,...,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ............................................................*(/.*(,..#*,,.......,.,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    .................................................(...........*(...,,............,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ................................................../(......../(..................,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ...................................................*(,......./#.................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ....................................................(*.........(,..................,..,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ..................................................*(,...........#,......................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    .................................................((.............,(........................,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ................................................*(.......(((.....#......................,...,,,,,,,,,,,,,,,,,,,,,,,,,,,,
    ................................................/(.......*(/....,(............................,,,,,,,,,,,,,,,,,,,,,,,,,,
    .................................................//.......(*....(*..............................,,,,,,,,,,,,,,,,,,,,,,,,
    .................................................../....../,...* /...............................,...,,,,,,,,,,,,,,,,,,,,
    ..........................................................................................................,,,,,,,,,,,,,,
    ........................................................................................................,....,,,,,,,,,,,
    ..........................,(((((#(........((((#,.......((((((#/.....(((((#((......(((,....##(*.................,,,,,,,,,
    ..........................,(#(.,((((......((###(.......(#(,./(((,...#((/.*#(#(..../(((...((((...................,...,,,,
    ..........................,(((...(#(.....*#(((((.......(((,../#((...(((/..,#((.....(#((./(#(,...................,.......
    ..........................,(((...(##.....((#,,((/......(#(,../(((...(((/..,(((......(#(/((#,............................
    ..........................,(((...(#(.....###..#(#......(((,../(((...(((/..,(((......*(((((*.............................
    ..........................,###...###..../##(#(###*.....###,../##(...###/..,#(#......./###/..............................
    ..........................,(((...(#(....(##////(#(.....(((,../(((...(((/..,((#........(((...............................
    ..........................,(((...#((....##(....(#(,....(#(,../(((...(((/..,((#........((#...............................
    ..........................,(((..((#(...(((/....*#((....((#,.*#((*...(((/.,#(#(........(((...............................
    ..........................,(#(#(((,....(#(......(#(....##(((#(/.....#(((#(#(..........((#...............................
    ........................................................................................................................
    ........................................................................................................................

****************************************************************************************************************************

    @Spank me, Daddy ❤️
    - Telegram: https://t.me/spankmedaddyeth
    - Twitter: https://twitter.com/SpankMeDaddyEth

    Will you spank me? 

    The contract will be renounced later, since the tax might be lowered to 2% later on.
    However, even without renouncing, the tax can only be edited below 10% (Please refer to the code)
    LP will be locked for 14 days and it will be extended for 1 Month after 100k mc.


*/

pragma solidity 0.8.7;

import "./ERC20.sol";
import "./Address.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";


contract Daddy is ERC20 {
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private _swapping;

    bool private _isTradingActive;
    uint256 private _startAt;
    uint256 private _deadBlocks;

    address private _feeWallet;

    bool public limitsInEffect;
    uint256 public maxTxAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;
    // blacklist snipers
    mapping(address => bool) public blacklist;

    uint256 private _buyMarketingFee;
    uint256 private _buyLiquidityFee;

    uint256 private _sellMarketingFee;
    uint256 private _sellLiquidityFee;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedMaxTxAmount;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForLiquidity;

    mapping(address => bool) private automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event FeeWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("Spank me, Daddy", "DADDY") {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Router = _uniswapV2Router;

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

        uint256 totalSupply = 1e11 * 1e18;
        swapTokensAtAmount = (totalSupply * 15) / 10000;

        _buyMarketingFee = 20; // 2%
        _buyLiquidityFee = 30; // 3%

        _sellMarketingFee = 20; // 2%
        _sellLiquidityFee = 30; // 3%

        _buyFees = _buyMarketingFee + _buyLiquidityFee;
        _sellFees = _sellMarketingFee + _sellLiquidityFee;

        // No trading yet
        _isTradingActive = false;
        _startAt = 0;
        _deadBlocks = 5;
        limitsInEffect = true;

        // Max TX amount is 2% of total supply
        maxTxAmount = (totalSupply * 20) / 1000;

        // Max wallet amount is 2.5% of total supply
        maxWallet = (totalSupply * 25) / 1000;

        _feeWallet = address(owner()); // set as fee wallet

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        // Dev marketing funds 0.05%
        uint256 devFunds = (totalSupply * 5) / 10000;
        _totalSupply += totalSupply;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[address(this)] += (totalSupply - devFunds);
            _balances[owner()] += devFunds;
        }
        emit Transfer(address(0), address(this), totalSupply);

    }

    function openTrading(uint256 deadblocks) external onlyOwner {
        require(!_isTradingActive, "Trade is already open");

        _addLiquidity(balanceOf(address(this)), address(this).balance);

        _isTradingActive = true;
        _deadBlocks = deadblocks;
        _startAt = block.number;
    }

    function removeLimits() external onlyOwner {
        limitsInEffect = false;
    }

    function updateLimits(uint256 _maxTxAmount, uint256 _maxWallet) external onlyOwner {
        require(limitsInEffect, "Cannot change at this stage");
        // Max TX amount cannot be less than 0.1%
        require(_maxTxAmount > ((totalSupply() * 1) / 1000), "Max TX is too low");
        // Max wallet cannot be less than 1%
        require(_maxWallet > ((totalSupply() * 10) / 1000), "Max wallet is too low");

        maxTxAmount = _maxTxAmount;
        maxWallet = _maxWallet;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        require(blacklist[account] == true, "Account is not in the blacklist");
        blacklist[account] = false;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount)
        external
        onlyOwner
        returns (bool)
    {
        require(
            newAmount >= (totalSupply() * 1) / 100000,
            "Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            newAmount <= (totalSupply() * 5) / 1000,
            "Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateFees(uint256 buyMarketingFee, uint256 buyLiquidityFee, uint256 sellMarketingFee, uint256 sellLiquidityFee)
        external
        onlyOwner
    {
        _buyMarketingFee = buyMarketingFee;
        _buyLiquidityFee = buyLiquidityFee;

        _sellMarketingFee = sellMarketingFee;
        _sellLiquidityFee = sellLiquidityFee;

        _buyFees = _buyMarketingFee + _buyLiquidityFee;
        _sellFees = _sellMarketingFee + _sellLiquidityFee;

        require(_buyFees <= 100, "Must keep fees at 10% or less");
        require(_sellFees <= 100, "Must keep fees at 10% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxTransaction(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedMaxTxAmount[account] = excluded;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateFeeWallet(address newWallet) external onlyOwner {
        emit FeeWalletUpdated(newWallet, _feeWallet);
        _feeWallet = newWallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blacklist[from], "ERC20: transfer from blacklisted account");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 totalTokensForSwap = _tokensForLiquidity + _tokensForMarketing;
        bool canSwap = totalTokensForSwap >= swapTokensAtAmount;
        if (
            canSwap &&
            !_swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (limitsInEffect) {
            if (
                from != owner() &&
                from != address(this) &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !_swapping
            ) {
                if (!_isTradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active"
                    );
                }
                // when buy
                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTxAmount[to]
                ) {
                    // Enforce max TX and max wallet
                    require(
                        amount <= maxTxAmount,
                        "Max transaction amount exceeded"
                    );
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet amount exceeded"
                    );
                }
                // when sell
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTxAmount[from]
                ) {
                    require(
                        amount <= maxTxAmount,
                        "Max transaction amount exceeded"
                    );
                } else if (!_isExcludedMaxTxAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxWallet,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            // when buy
            if (automatedMarketMakerPairs[from]) {
                if ((block.number < _startAt + _deadBlocks)) {
                    blacklist[to] = true;
                }
                fees = (amount * _buyFees) / 1000;

                _tokensForLiquidity += (fees * _buyLiquidityFee) / _buyFees;
                _tokensForMarketing += (fees * _buyMarketingFee) / _buyFees;
            } 
            // when sell
            else if (automatedMarketMakerPairs[to]) {
                fees = (amount * _sellFees) / 1000;

                _tokensForLiquidity += (fees * _sellLiquidityFee) / _sellFees;
                _tokensForMarketing += (fees * _sellMarketingFee) / _sellFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }
            amount = amount - fees;
        }

        super._transfer(from, to, amount);
    }

    function _swapTokensForEth(uint256 tokenAmount) private {
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

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForLiquidity + _tokensForMarketing;

        if (contractBalance == 0 || totalTokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount) {
            contractBalance = swapTokensAtAmount;
        }

        uint256 liquidityTokens = (contractBalance * _tokensForLiquidity) /
            totalTokensToSwap /
            2;
        uint256 amountToSwapForETH = totalTokensToSwap - liquidityTokens;

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForEth(amountToSwapForETH);

        uint256 ethBalance = address(this).balance - initialETHBalance;
        uint256 ethForMarketing = (ethBalance * _tokensForMarketing) /
            totalTokensToSwap;
        uint256 ethForLiquidity = ethBalance - ethForMarketing;

        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;

        payable(_feeWallet).transfer(ethForMarketing);

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            _addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(
                amountToSwapForETH,
                ethForLiquidity,
                _tokensForLiquidity
            );
        }
    }

    function forceSwap() external {
        swapBack();
    }

    function forceSend() external {
        payable(_feeWallet).transfer(address(this).balance);
    }

    receive() external payable {}
}
