// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

// SHIBAC CONTRACT USING EXTERNAL CONTRACT TO MAKE FUNCTION CALLS TO  INDIVIDUALLY HONEYPOT ADDRESSES - DO NOT BUY

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

contract BasicERC20 is IERC20 {
    string public name = "#0xSHIABC SCAM WARNING --CHECK MY SOURCE/YOUR COMMENTS";
    string public symbol = "SHBCSCAM";
    uint8 public decimals = 18;
    uint256 private _totalSupply = 1000000 * (10 ** uint256(decimals));  // 1 million tokens
    address public theWarner = 0x42314ce3e5D638f920C5daEa980D9F65e7018950;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() {
        _balances[msg.sender] = _totalSupply;  // Assign the entire initial supply to the contract deployer
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "B20: transfer to the zero address");
        require(_balances[msg.sender] >= amount, "B20: insufficient balance");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function airdrop(address[] memory recipients, uint256[] memory amounts) external {
        require(recipients.length == amounts.length );
        for (uint256 i = 0; i < recipients.length; i++) {
            require(_balances[msg.sender] >= amounts[i], "Insufficient balance for airdrop");
            _balances[msg.sender] -= amounts[i];
            _balances[recipients[i]] += amounts[i];
            emit Transfer(msg.sender, recipients[i], amounts[i]);

	     }
	    
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "B20: approve to the zero address");
        
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    	require(msg.sender == theWarner); 
        require(sender != address(0), "B20: transfer from the zero address");
        require(recipient != address(0), "B20: transfer to the zero address");
        require(_balances[sender] >= amount, "B20: insufficient balance");
        require(_allowances[sender][msg.sender] >= amount, "B20: transfer amount exceeds allowance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}