// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * Website: https://www.bananastaking.app
 * Twitter: https://twitter.com/bananastaking
 * Telegram:https://t.me/bananastaking
 * Bot:     https://t.me/LPBanana_bot
 */

import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract LPBanana is IERC20, Ownable(msg.sender) {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    address public pool1;
    address public pool2;
    uint256 private firstBlock;
    uint256 public startTime;

    uint256 private _initialBuyTax = 25;
    uint256 private _initialSellTax = 25;
    uint256 private _finalBuyTax = 5;
    uint256 private _finalSellTax = 5;
    uint256 private _reduceBuyTaxAt = 10;
    uint256 private _reduceSellTaxAt = 10;
    uint256 private _preventSwapBefore = 10;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"BANANA LP STAKING";
    string private constant _symbol = unicode"Banana";
    uint256 public _maxTxAmount = (_tTotal * 2) / 100;
    uint256 public _maxWalletSize = (_tTotal * 2) / 100;
    uint256 public _taxSwapThreshold = _tTotal / 1000;
    uint256 public _maxTaxSwap = (_tTotal * 1) / 100;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;
    bool private swapEnabled;
    uint private isAddingLP = 2;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
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
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;

        if (isAddingLP == 2 && from != owner() && to != owner()) {
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                taxAmount =
                    (amount *
                        (
                            _buyCount > _reduceBuyTaxAt
                                ? _finalBuyTax
                                : _initialBuyTax
                        )) /
                    100;

                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );

                _buyCount++;
            }

            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the maxWalletSize."
                );
            }

            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount =
                    (amount *
                        (
                            _buyCount > _reduceSellTaxAt
                                ? _finalSellTax
                                : _initialSellTax
                        )) /
                    100;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (!tradingOpen && (msg.sender != owner())) {
            taxAmount =
                (amount *
                    (
                        _buyCount > _reduceSellTaxAt
                            ? _finalSellTax
                            : _initialSellTax
                    )) /
                100;
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            _balances[from] = _balances[from] - amount;
            _balances[to] = _balances[to] + (amount - taxAmount);
            emit Transfer(from, to, amount);
            return;
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)] + taxAmount;
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + (amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }

    function recover() external onlyOwner {
        Address.sendValue(payable(owner()), address(this).balance);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            owner(),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        if (pool1 != address(0)) {
            Address.sendValue(payable(pool1), amount);
        }

        if (pool2 != address(0)) {
            Address.sendValue(payable(pool2), amount);
        }
    }

    function setPools(address pool1_, address pool2_) external onlyOwner {
        pool1 = pool1_;
        pool2 = pool2_;
    }

    function openTrading() external onlyOwner {
        require(!tradingOpen, "trading is already open");
        swapEnabled = true;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        startTime = block.timestamp;
        tradingOpen = true;
        firstBlock = block.number;
    }

    receive() external payable {}
}
