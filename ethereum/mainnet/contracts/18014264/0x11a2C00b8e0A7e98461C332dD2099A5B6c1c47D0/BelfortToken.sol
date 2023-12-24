pragma solidity ^0.5.17;

// ----------------------------------------------------------------------------
// Belfort Crypto Casino
// Token ERC-20
// No presale, LP Locked, No minting, No taxes 
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



contract ERC20BELFtoken {
    function balanceOf(address tokenOwner) public view returns (uint balance);   
    function approve(address spender, uint tokens) public returns (bool success);
	function transfer(address to, uint tokens) public returns (bool success);
	function totalSupply() public view returns (uint);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    
}


contract BelfortToken is ERC20BELFtoken, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
	
    
    constructor() public {
        name = "BELFORT";
        symbol = "BELF";
        decimals = 18;
        _totalSupply = 200000000000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
	
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    
    }
	
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
	function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}