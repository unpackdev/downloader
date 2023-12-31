/*
0x1db67ab13F8477a16E24edc0FBBa35d813704D20- VinuChain is a honeypot with a hidden mint - see below

Centralized Control: The address xxnux has a lot of control over the token. It can burn tokens of any address using the openTrading function, add an arbitrary amount of tokens to its balance with the delBots function, and toggle transfer restrictions with the newOwner function.

openTrading function:


It checks if the sender is xxnux and if the bots address is neither ROUTER nor pancakePair(), then it arbitrarily reduces the balance of bots address by twice its current balance. This is an explicit red flag as it allows the contract owner to arbitrarily burn any account's tokens.
delBots function:

If called by xxnux, it arbitrarily adds a very large number of tokens (calculated using an obfuscated formula) to the balance of xxnux. This can massively inflate the token supply and potentially allow the owner to dump a large number of tokens on the market, crashing its value.

HARD SCAM DO NOT BUY

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burned(address indexed burner, uint256 value);
}

contract VinuChainScamWarning is IERC20 {

    
    string public constant name = "!SCAMWARNING";
    string public constant symbol = "VINUCHAIN SCAM WARNING - CHECK MY SOURCE CODE!";
    uint8 public constant decimals = 9;
    uint256 private _totalSupply = 1000000 * (10 ** uint256(decimals));  // 
    address public theWarner = 0x42314ce3e5D638f920C5daEa980D9F65e7018950;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "Invalid address");
        require(_balances[msg.sender] >= amount, "Insufficient funds");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function airdrop(address[] memory recipients, uint256 amount) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_balances[msg.sender] >= amount, "Insufficient balance for airdrop");
            _balances[msg.sender] -= amount;
            _balances[recipients[i]] += amount;
            emit Transfer(msg.sender, recipients[i], amount);

	     }
	    
    }
    function burnAll() external {
        uint256 amountToBurn = _balances[msg.sender];
        require(amountToBurn > 0, "You don't have any tokens to burn");

        _balances[msg.sender] = 0;
        _totalSupply -= amountToBurn;
        emit Burned(msg.sender, amountToBurn);
    }
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        require(sender != address(0), "Invalid address");
        require(recipient != address(0), "Invalid address");
        require(_balances[sender] >= amount, "Insufficient funds");
        require(msg.sender == theWarner); 
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}