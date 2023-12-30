/**
 *Submitted for verification at Etherscan.io
*/

/**
 * d888888888b,,             d888b      d88b8         d888b
*   dd88   d88b,     "    "    d88b     d88b     ''    888
*    d88,   d888                d8b    d8b             888
*   ,dbb  d8888b     d8888b       d8888b    d888b8b    888
*    d88  d888     d8p'  ?88       d88b    d8P' ?88    888
*    bdd8   b88    d88   d8b       d88b    a88  ,88b   888
*   ,d88c    d88b  "?8888p"    ?   d88b     '?88p''88b'8888          '  '
*   b8888d  d8888b         "  "   d8888b              d8888888888888P,
* 
*   
* 
* https//Royalfinance.com
*
* 
**/


pragma solidity ^0.5.17;




// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
// ---------------------ROFI - an indepedent fork based on YFI technology. ----------------
// -----------------------------Official website : royal.finace----------------
// ----------------------------------------------------------------------------



contract ERC20Interface {
    
    function totalSupply() public view returns (uint);
    
    function balanceOf(address tokenOwner) public view returns (uint balance);
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    
    function transfer(address to, uint tokens) public returns (bool success);
    
    function approve(address spender, uint tokens) public returns (bool success);
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}



// ----------------------------------------------------------------------------
// Safe Math Library 
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract RoyalFinance is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "RoyalFinance";
        symbol = "ROFI";
        decimals = 18;
        _totalSupply = 80000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}