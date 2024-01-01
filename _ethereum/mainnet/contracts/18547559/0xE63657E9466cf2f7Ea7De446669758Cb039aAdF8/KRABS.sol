// SPDX-License-Identifier: MIT

/*
Ahoy there, me hearties!

It's your old pal, Mr. Eugene Harold Krabs, and I've got some exciting news for all ye landlubbers and crypto enthusiasts out there. I'm proud to announce the launch of our very own crypto token, $KRABS!


Website: https://mrkrabs.live
Telegram: https://t.me/krabsfun_erc
Twitter: https://twitter.com/krabsfun_erc
*/

pragma solidity 0.8.19;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDexRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract KRABS is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name= "Krabs";
    string private constant _symbol= "KRABS";

    uint8 private constant _decimals= 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private _initialBuyTax=15;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=2;
    uint256 private _finalSellTax=2;
    uint256 private _reduceBuyTaxAt=25;
    uint256 private _reduceSellTaxAt=35;
    uint256 private _preventSwapBefore=15;
    uint256 private numBuyers=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromFees;

    IDexRouter private _dexRouter;
    address private _dexPair;
    bool private _tradeActive;
    bool private _inswap= false;
    bool private _swapEnabled= false;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public swapThreshold = 10 ** 5 * 10**_decimals;
    uint256 public swapFeeMax = 10 ** 7 * 10**_decimals;
    address payable private _devAddress = payable(0x5dDe4e7aE5899369679f14C6e8C2992d7e78fdBb);

    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockTheSwap {
        _inswap = true;
        _;
        _inswap = false;
    }

    constructor () {
        _balances[address(this)] = _totalSupply;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[_devAddress] = true;

        emit Transfer(address(0), address(this), _totalSupply);
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function sendFees(uint256 amount) private {
        _devAddress.transfer(amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeAmount = 0;
        if (from != owner() && to != owner() && !isExcludedFromFees[from]) {
            feeAmount = amount.mul((numBuyers > _reduceBuyTaxAt) ? _finalBuyTax  :_initialBuyTax).div(100);

            if (from == _dexPair && to != address(_dexRouter) && !isExcludedFromFees[to]) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                numBuyers++;
            }

            if (to == _dexPair && from != address(this)) {
                feeAmount = amount.mul((numBuyers>_reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_inswap && to == _dexPair && _swapEnabled && contractTokenBalance > swapThreshold && numBuyers > _preventSwapBefore && amount > swapThreshold) {
                swapTokensForETH(min(amount, min(contractTokenBalance, swapFeeMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendFees(address(this).balance);
                }
            }
        }

        if (feeAmount > 0) {
          _balances[address(this)] = _balances[address(this)].add(feeAmount);
          _balances[from] = _balances[from].sub(amount);
          emit Transfer(from, address(this), feeAmount);
        }
        _balances[to] = _balances[to].add(amount.sub(feeAmount));
        emit Transfer(from, to, amount.sub(feeAmount));
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
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
    
    function openTrading() external onlyOwner() {
        require(!_tradeActive, "Trading is already open");
        _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_dexRouter), _totalSupply);
        _dexPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _dexRouter.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_dexPair).approve(address(_dexRouter), type(uint).max);
        _swapEnabled = true;
        _tradeActive = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }

    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = maxTxAmount = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }
}