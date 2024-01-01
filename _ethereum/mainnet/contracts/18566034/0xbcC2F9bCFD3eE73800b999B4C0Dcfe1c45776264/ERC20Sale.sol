// SPDX-License-Identifier: MIT
// File: BITBLACK/SafeMath.sol


pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

// File: BITBLACK/IERC20.sol


pragma solidity ^0.8.0;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: BITBLACK/MyToken.sol


pragma solidity ^0.8.0;



contract MyToken is IERC20 {
    using SafeMath for uint256;

    string private _name = "Bitblack";
    string private _symbol = "BTk";
    uint8 private _decimals = 18;
    uint256 private _totalSupply;
    address public _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(uint256 totalSupply_ ) {
        _totalSupply = totalSupply_.mul(10**uint256(_decimals));
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance.sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "MyToken: approve from the zero address");
        require(spender != address(0), "MyToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}

// File: BITBLACK/ERC20Sale.sol


pragma solidity ^0.8.0;


contract ERC20Sale {
    address payable public owner;
    MyToken public token;
    uint256 public tokenPrice;
    uint256 public soldTokens;

    event Sell(address _buyer, uint256 _amount);

    constructor(MyToken _token, uint256 _tokenPrice) {
        owner = payable(msg.sender);
        token = _token;
        tokenPrice = _tokenPrice; // 100000000000000000;  0.1 ETH in Wei
        //tokenPrice = 1250000000000;
    }
   
    receive() external payable {
        uint256 _numberOfTokens = msg.value / tokenPrice;
        uint256 tokensAllowed  = token.allowance(token.getOwner(), address(this));
        require(tokensAllowed  >= _numberOfTokens, "Not enough tokens approved for sale.");

        soldTokens += _numberOfTokens;

        token.transferFrom(token.getOwner(), msg.sender, _numberOfTokens);
        owner.transfer(address(this).balance);

        emit Sell(msg.sender, _numberOfTokens);
    }
    function tokenSold() public view  returns (uint256){
        require(msg.sender == owner, "Only the owner can end the sale.");

        return soldTokens;
    }

    function endSale() public {
        require(msg.sender == owner, "Only the owner can end the sale.");

        uint256 unsoldTokens = token.balanceOf(address(this));
        require(unsoldTokens > 0, "There are no unsold tokens.");

        token.transfer(owner, unsoldTokens);
    }
}