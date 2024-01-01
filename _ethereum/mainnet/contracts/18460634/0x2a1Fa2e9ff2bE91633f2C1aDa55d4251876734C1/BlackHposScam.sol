/*

0x1d17fCA92182F238dE7194a6BfFF883a13F17A2D - Honeypot contract / hidden mint 

Minting: There's an _DeployBlackrock function that appears to be used for minting tokens. Minting functions are commonly found in ERC20 contracts. This funciton can be used to mint tokens after as well as during deployment.

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
}

contract BlackHposScam is IERC20 {

    
    string public constant name = "*SCAMWARNING";
    string public constant symbol = "BlackHarryPotterObamaSonicRock69Inu SCAM WARNING - CHECK MY SOURCE CODE!";
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