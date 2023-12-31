// SPDX-License-Identifier: The Unlicense

pragma solidity ^0.4.24;

// Safe Math Interface
contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ERC Token Standard #20 Interface
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// Contract function to receive approval and execute function in one call
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// Actual token contract
contract Token is ERC20Interface, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    address public contractOwner; // Contract owner address

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint public buyTaxPercentage;
    uint public sellTaxPercentage;

    constructor() public {
        symbol = "CAT";
        name = "CATECOIN";
        decimals = 2;
        _totalSupply = 10000000000000;
        balances[0xB05Bb6AD3842A301A2E32f37E2c1D75f51bD7baA] = _totalSupply;
        emit Transfer(address(0), 0xB05Bb6AD3842A301A2E32f37E2c1D75f51bD7baA, _totalSupply);

        buyTaxPercentage = 3; // Set buy tax percentage
        sellTaxPercentage = 4; // Set sell tax percentage

contractOwner = msg.sender; // Set the contract owner as the deployer of the contract
    }

    function totalSupply() public constant returns (uint) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        uint taxAmount = safeMul(tokens, sellTaxPercentage) / 100;
        require(tokens >= taxAmount);

        uint transferAmount = safeSub(tokens, taxAmount);

        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], transferAmount);
        balances[contractOwner] = safeAdd(balances[contractOwner], taxAmount); // Tax is paid to the contract owner

        emit Transfer(msg.sender, to, transferAmount);
        emit Transfer(msg.sender, contractOwner, taxAmount);

        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        uint taxAmount = safeMul(tokens, sellTaxPercentage) / 100;
        require(tokens >= taxAmount);

        uint transferAmount = safeSub(tokens, taxAmount);

        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], transferAmount);
        balances[contractOwner] = safeAdd(balances[contractOwner], taxAmount); // Tax is paid to the contract owner

        emit Transfer(from, to, transferAmount);
        emit Transfer(from, contractOwner, taxAmount);

        return true;
    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    function () public payable {
        revert();
    }
}