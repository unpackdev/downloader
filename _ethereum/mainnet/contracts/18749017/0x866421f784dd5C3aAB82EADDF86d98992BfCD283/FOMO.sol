// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    // Section 1: State variables
    string public symbol = "FMO";
    string public name = "FOMO";
    uint8 public decimals = 18;
    uint public _totalSupply = 21_000_000_000 * 10**18;
    address public owner;
    address public myWallet;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    uint public lastActionTimestamp;
    uint public antiBotDelay = 1 minutes;
    using SafeMath for uint;

    // ... (other declarations)

    uint public initialPrice = 1000000000; // Initial price of the token in wei ($0.000001 equivalent)

    uint public priceMultiplier = 100000001;

    // Section 2: Constructor
    constructor() {
        owner = msg.sender;
        myWallet = 0x02d515bC4F21F5ad88c6c43486f0C71317cb73d1;
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    // Section 3: Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyAfterDelay() {
        require(block.timestamp > lastActionTimestamp + antiBotDelay, "Anti-bot delay not elapsed");
        _;
    }

    // Section 4: ERC20 Functions
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public onlyAfterDelay returns (bool success) {
        balances[msg.sender] = balances[msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(msg.sender, to, tokens);
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
        balances[from] = balances[from].safeSub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].safeSub(tokens);
        balances[to] = balances[to].safeAdd(tokens);
        emit Transfer(from, to, tokens);
        lastActionTimestamp = block.timestamp;
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Section 5: Additional Functions
    function adjustPrice(uint tokensBought) internal {
        uint newPrice = initialPrice * priceMultiplier**tokensBought;
        require(newPrice > initialPrice, "FOMO: Price must increase");
        initialPrice = newPrice;
    }

    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        owner = newOwner;
    }

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}