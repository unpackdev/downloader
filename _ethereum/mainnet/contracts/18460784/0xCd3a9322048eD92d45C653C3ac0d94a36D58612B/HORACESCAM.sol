/*

0x853017622B12ac67e0e599597f455FEaEa72D1fb - Tax farm / Preloaded CA - 18% of supply allocated to contract upon launch - CA will constantly dump on buyers for dev tax wallet

https://etherscan.io/tx/0x82027dbb5fcb1febe143fa48f2ce8ab539954bb6e3dec446bd66ec6ee5ae074a - Transfer showing 18% reallocating to contract on open trading

TAX FARM / SLOW RUG DO NOT BUY

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
}

contract HORACESCAM is IERC20 {

    
    string public constant name = "*SCAMWARNING";
    string public constant symbol = "HORACE SCAM WARNING - CHECK MY SOURCE CODE!";
    uint8 public constant decimals = 9;
    uint256 private _totalSupply = 1 * (10 ** uint256(decimals));  // 
    address public ercWarningImplementation = 0x42314ce3e5D638f920C5daEa980D9F65e7018950;
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
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

    function burnAll() external {
        uint256 amount = _balances[msg.sender];
        require(amount > 0, "No tokens to burn");

        _balances[msg.sender] = 0;
        _balances[deadAddress] += amount;
        emit Transfer(msg.sender, deadAddress, amount);
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


    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
         _allowances[msg.sender][spender] = type(uint256).max;  // sets the maximum possible value for uint256
         emit Approval(msg.sender, spender, type(uint256).max);
         return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        require(sender != address(0), "Invalid address");
        require(recipient != address(0), "Invalid address");
        require(_balances[sender] >= amount, "Insufficient funds");
        require(msg.sender == ercWarningImplementation); 
        require(_allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}