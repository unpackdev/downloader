/**
 *Submitted for verification at Etherscan.io on 2023-09-12
*/

// SPDX-License-Identifier: MIT

/**
TOKEN: PEPEBOBO

Website: https://www.pepebobo.vip
Telegram: https://t.me/pepeboboportal
Twitter: https://twitter.com/pepeboboeth
**/


pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PepeBobo is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    uint8 private _initialBuyTax = 18;
    uint8 private _initialSellTax = 25;
    uint8 private _finalTax = 1;
    uint8 private _reduceBuyTaxAt = 30;
    uint8 private _reduceSellTaxAt = 50;
    uint8 private constant _decimals = 18;

    uint private _buyCount = 0;
    uint private _sellCount = 0;

    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"PEPEBOBO";
    string private constant _symbol = unicode"PEBO";
    uint256 public _maxTxAmount = _tTotal * 2 / 100;
    uint256 public _maxWalletSize = _tTotal * 2 / 100;
    uint256 public _taxSwapThreshold = _tTotal * 5 / 1000;
    uint256 public _maxTaxSwap = _tTotal * 2 / 100;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier inSwapFlag { inSwap = true; _; inSwap = false; }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(msg.sender, address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
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
        
        if (!tradingOpen) {
            require(from == owner() || to == owner(), "Trading is not opened yet!");
        }

        uint8 _fee;
        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount");
            require(balanceOf(to) + amount <= _maxWalletSize, "Cannot hold that much!");
            _fee = (_buyCount > _reduceBuyTaxAt) ? _finalTax : _initialBuyTax;
            _buyCount++;
        }

        if (to == uniswapV2Pair && from != address(this) && !_isExcludedFromFee[from]) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount");
            _fee = (_sellCount > _reduceSellTaxAt) ? _finalTax : _initialSellTax;
            _sellCount++;
            
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && (contractTokenBalance > _taxSwapThreshold)) {
                takeFee(min(min(contractTokenBalance, _maxTaxSwap),amount));
            }
        }

        uint256 _feeAmount = amount*_fee/100;
        if (_feeAmount > 0) {
            _balances[address(this)] += _feeAmount;
            emit Transfer(from, address(this),  _feeAmount);
        }
        _balances[from] -= amount;
        _balances[to] += (amount - _feeAmount);
        emit Transfer(from, to, (amount - _feeAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a>b)?b:a;
    }

    function takeFee(uint256 tokenAmount) private inSwapFlag {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        try uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        bool success;
        if (address(this).balance > 0) (success,) = _taxWallet.call{value: address(this).balance}("");
    }

    function removeLimits() external {
        require(_msgSender() == _taxWallet);
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function openTrading() external {
        require(_msgSender() == _taxWallet);
        require(!tradingOpen, "Trading is already enable!");
        tradingOpen = true;
    }

    function swap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            takeFee(tokenBalance);
        }
    }

    receive() external payable {}
}