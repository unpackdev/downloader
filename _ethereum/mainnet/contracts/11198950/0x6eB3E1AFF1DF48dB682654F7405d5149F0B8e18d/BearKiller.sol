/**
    https://t.me/bearkiller
*/

pragma solidity ^0.5.17;

contract SafeMath {
    
    // Check for overflows.
    
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

contract ERC20Interface

{
    // Get total supply of tokens.
    
    function totalSupply() public view returns (uint);

    // Find out a user's balance.
    
    function balanceOf(address tokenOwner) public view returns (uint balance);
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    // Perform safe and authorized fund transfers from one user to another.
    
    function transfer(address to, uint tokens) public returns (bool success);
    
    // Allow spender to withdraw tokens from account.
    
    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom (address from, address to, uint tokens) public returns (bool success);

    // Initialize burn function.
    
    function burn(uint256 _value) public {_burn(msg.sender, _value);}
    
    function _burn(address sender, uint amount) public {
        
    }
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
}


contract BearKiller is ERC20Interface, SafeMath

{
    string public name;
    string public symbol;
    uint8 public decimals;
    bool public firstTransfor;
    address public burnaddress = 0x000000000000000000000000000000000000dEaD;
    uint public numerator = 2; // Set burn numerator to 2.
    uint public denominator = 100; // Set burn denomator to 100. 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address =>uint)) allowed;
    
    constructor() public
    
    {
        name = "BearKiller";
        symbol = "$BKILL";
        decimals = 18;
        _totalSupply = 5000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) 
    
    {
        return _totalSupply - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) 
    
    {
        return balances[tokenOwner];
    }
    
    function allowance (address tokenOwner, address spender) public view returns (uint remaining) 
    
    {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) 
    
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success)
    
{
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens - ((tokens * numerator) / denominator)); // Burn rate of 2%.
    
    _burn(burnaddress, tokens);
    emit Transfer(msg.sender, to, tokens - ((tokens * numerator) / denominator));
    emit Transfer(msg.sender, burnaddress, ((tokens * numerator) / denominator));
    return true;
}
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) 

{
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], (tokens - ((tokens * numerator) / denominator)));
    balances[to] = safeAdd(balances[to], (tokens - ((tokens * numerator) / denominator)));    
    _burn(burnaddress, tokens);

emit Transfer(from, to, (tokens - ((tokens * numerator) / denominator)));
  emit Transfer(from, burnaddress, ((tokens * numerator) / denominator));
    return true; 
}
 
}