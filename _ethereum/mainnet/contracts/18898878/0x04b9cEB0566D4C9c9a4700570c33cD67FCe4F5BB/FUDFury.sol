// contracts/FUDFury.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract FUDFury {
    string public constant name = "FUDFury";
    string public constant symbol = "FFURY";
    uint8 public constant decimals = 18;
    uint public totalSupply = 24000000 * (10 ** uint(decimals));
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    address public owner = 0xB0399486C552b58490248D7E1a800504B1315C9f;
    uint public constant taxPercentage = 3;

    event Transfer(address indexed from, address indexed to, uint tokens, bool isBuy);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        balances[owner] = totalSupply; 
        emit Transfer(address(0), owner, totalSupply, false);
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens, "Insufficient balance");

        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens, false);

        return true;
    }

    function buy(uint tokens) public returns (bool success) {
        uint taxAmount = (tokens * taxPercentage) / 100;
        uint tokensAfterTax = tokens - taxAmount;

        require(balances[owner] >= tokensAfterTax, "Insufficient balance");

        balances[owner] -= tokensAfterTax;
        balances[msg.sender] += tokensAfterTax;
        emit Transfer(owner, msg.sender, tokensAfterTax, true);

        _applyTax(taxAmount);

        return true;
    }

    function sell(uint tokens) public returns (bool success) {
        uint taxAmount = (tokens * taxPercentage) / 100;
        uint tokensAfterTax = tokens - taxAmount;

        require(balances[msg.sender] >= tokens, "Insufficient balance");

        balances[msg.sender] -= tokens;
        balances[owner] += tokensAfterTax;
        emit Transfer(msg.sender, owner, tokensAfterTax, false);

        _applyTax(taxAmount);

        return true;
    }

    function _applyTax(uint taxAmount) internal {
        balances[owner] += taxAmount;
        emit Transfer(msg.sender, owner, taxAmount, false);
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint taxAmount = (tokens * taxPercentage) / 100;
        uint tokensAfterTax = tokens - taxAmount;

        require(tokens <= balances[from], "Insufficient balance");
        require(tokens <= allowed[from][msg.sender], "Allowance exceeded");

        balances[from] -= tokens;
        balances[to] += tokensAfterTax;
        allowed[from][msg.sender] -= tokens;
        emit Transfer(from, to, tokensAfterTax, false);
        _applyTax(taxAmount);

        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function burn(uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");
        totalSupply -= amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, address(0), amount, false);
    }
}