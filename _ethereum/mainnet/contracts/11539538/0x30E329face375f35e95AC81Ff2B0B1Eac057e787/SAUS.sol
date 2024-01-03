pragma solidity ^0.4.24;

// Sauce SToken Contract
//
// Symbol        : SAUS
// Name          : Sauce SToken
// Total supply  : 111,212,272
// Decimals      : 5
// Owner Account : 0x6D92045687E5A6c9798184Da3392466633B5380E
//
// (c) by Adam Pontoni 2020 - MIT Licence.


    //  SafeMatch Check  //
    
contract SafeMath {

    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


    //  Standard ERC20Interface  //
    
contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address tokenOwner) public constant returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


    //  Receive approval and execute function in one call  //
    //  Borrowed from MiniMeToken                          //

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

    //  Token Declarations  //
    
contract SAUS is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint256 public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;


    
    //  Constructor  //
    
    constructor() public {
        symbol = "SAUS";
        name = "Sauce SToken";
        decimals = 5;
        _totalSupply = 11121227200000;
        balances[0x6D92045687E5A6c9798184Da3392466633B5380E] = _totalSupply;
        emit Transfer(address(0), 0x6D92045687E5A6c9798184Da3392466633B5380E, _totalSupply);
    }


   
    //  Total supply  //
    
    function totalSupply() public constant returns (uint256) {
        return _totalSupply  - balances[address(0)];
    }


 
    //  Get the token balance for account tokenOwner  //
  
    function balanceOf(address tokenOwner) public constant returns (uint256 balance) {
        return balances[tokenOwner];
    }


   
    //  Transfer the balance from Owner account to to account   //
    //  Owner account must have sufficient balance to transfer  //
    //  0 value transfers are allowed                           //
  
    function transfer(address to, uint256 tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    
    //  Token owner can approve for spender to transferFrom() tokens from Owner account //

    function approve(address spender, uint256 tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }



    //  Transfers tokens from the "from" account to the "to" account  //
   
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }



    //  Returns the amount of tokens approved that are transferrable to spender  //
 
    function allowance(address tokenOwner, address spender) public constant returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }


    
    // Token Owner approves transferFrom() then receiveApproval() is executed  // 
    
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    
    //  ETH Fallback function
    
    function () public payable {
        revert();
    }
}