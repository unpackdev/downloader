// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// SafeMath library to perform arithmetic operations safely
library SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "SafeMath: addition overflow");
    }

    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "SafeMath: subtraction overflow");
        c = a - b;
    }

    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "SafeMath: multiplication overflow");
    }

    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "SafeMath: division by zero");
        c = a / b;
    }
}

contract FOMO {
    using SafeMath for uint;

    string public symbol;
    string public name = "FOMO";
    uint8 public decimals;
    uint public _totalSupply = 21_000_000_000 * 10**18; // Set the total supply to 21 billion tokens

    address public owner;
    address public myWallet; // Your wallet address variable

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    uint public initialPrice = 0.00000000001 ether; // Initial price of the token
    uint public priceMultiplier = 100001; // Price multiplier for each token bought
    uint public lastActionTimestamp;
    uint public antiBotDelay = 1 minutes; // Set the anti-bot delay to 1 minute

    uint public buyTax = 5; // 5% tax on buy
    uint public swapTransferTax = 3; // 3% tax on swap transfer
    uint public sellTax = 8; // 8% tax on sell

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyAfterDelay() {
        require(block.timestamp > lastActionTimestamp + antiBotDelay, "Anti-bot delay not elapsed");
        _;
    }

    constructor() {
        owner = msg.sender; // Set the deployer's address as the owner
        myWallet = 0x02d515bC4F21F5ad88c6c43486f0C71317cb73d1; // Replace with your wallet address
        symbol = "FMO";
        decimals = 18;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public onlyAfterDelay returns (bool success) {
        adjustPrice(tokens);
        uint taxedTokens = calculateTransferTax(tokens, sellTax);
        balances[msg.sender] = balances[msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(taxedTokens);
        emit Transfer(msg.sender, to, taxedTokens);
        lastActionTimestamp = block.timestamp;
        return true;
    }

    function approve(address spender, uint tokens) public onlyAfterDelay returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        lastActionTimestamp = block.timestamp;
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public onlyAfterDelay returns (bool success) {
        adjustPrice(tokens);
        uint taxedTokens = calculateTransferTax(tokens, swapTransferTax);
        balances[from] = balances[from].safeSub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(taxedTokens);
        emit Transfer(from, to, taxedTokens);
        lastActionTimestamp = block.timestamp;
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function adjustPrice(uint tokensBought) internal {
        uint newPrice = initialPrice * priceMultiplier**tokensBought;
        require(newPrice > initialPrice, "FOMO: Price must increase");
        initialPrice = newPrice;
    }

    function calculateTransferTax(uint tokens, uint taxPercentage) internal pure returns (uint) {
        uint tax = tokens * taxPercentage / 100;
        return tokens.safeSub(tax);
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}