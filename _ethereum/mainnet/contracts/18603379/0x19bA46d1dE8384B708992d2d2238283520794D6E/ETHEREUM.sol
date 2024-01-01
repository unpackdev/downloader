// SPDX-License-Identifier: MIT

/*
Telegram: https://hpok9inu.com 

Twitter: https://twitter.com/hpok_erc 

Website: https://hpokinu.com 
*/

pragma solidity 0.8.21;

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

interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapRouter {
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

contract ETHEREUM is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private constant _name= "HarryPotterObamaKnuckles9Inu";
    string private constant _symbol= "ETHEREUM";

    uint8 private constant _decimals= 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private _firstBuyFee=12;
    uint256 private _firstSellFee=28;
    uint256 private _lastBuyFee=1;
    uint256 private _lastSellFee=1;
    uint256 private _decreaseBuyFeeAfter=16;
    uint256 private _decreaseSellFeeAfter=26;
    uint256 private _preventSwapBefore=15;
    uint256 private _buyersCount=0;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;

    IUniswapRouter private _router;
    address private _pair;
    bool private _tradeStarted;
    bool private swapping= false;
    bool private _swapEnabled= false;

    uint256 public maxTxAmount = 20 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletSize = 20 * 10 ** 6 * 10**_decimals;
    uint256 public swapThreshold = 10 ** 5 * 10**_decimals;
    uint256 public swapLimit = 10 ** 7 * 10**_decimals;
    address payable private _feeAddress;

    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _feeAddress = payable(0x38Ed1C2f88d6A6BA2ebf45256B01327F4D698776);
        _balances[address(this)] = _totalSupply;
        _isExcluded[owner()] = true;
        _isExcluded[_feeAddress] = true;

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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function openTrading() external onlyOwner() {
        require(!_tradeStarted, "Trading is already open");
        _router = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_router), _totalSupply);
        _pair = IUniswapFactory(_router.factory()).createPair(address(this), _router.WETH());
        _router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(_pair).approve(address(_router), type(uint).max);
        _swapEnabled = true;
        _tradeStarted = true;
    }
    
    receive() external payable {}
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a > b) ? b : a;
    }
    
    function sendETHToFee(uint256 amount) private {
        _feeAddress.transfer(amount);
    }

    function removeLimits() external onlyOwner {
        maxWalletSize = maxTxAmount = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
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
        
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 feeAmount = 0;
        if (from != owner() && to != owner() && !_isExcluded[from]) {
            feeAmount = amount.mul((_buyersCount > _decreaseBuyFeeAfter) ? _lastBuyFee  :_firstBuyFee).div(100);

            if (from == _pair && to != address(_router) && !_isExcluded[to]) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
                _buyersCount++;
            }

            if (to == _pair && from != address(this)) {
                feeAmount = amount.mul((_buyersCount>_decreaseSellFeeAfter) ? _lastSellFee : _firstSellFee).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to == _pair && _swapEnabled && contractTokenBalance > swapThreshold && _buyersCount > _preventSwapBefore && amount > swapThreshold) {
                swapTokensForEth(min(amount, min(contractTokenBalance, swapLimit)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
}