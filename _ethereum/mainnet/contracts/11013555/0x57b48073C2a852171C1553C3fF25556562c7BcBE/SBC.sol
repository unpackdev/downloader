pragma solidity ^0.4.24;

contract SafeMath {
  function safeSub(uint256 a, uint256 b) public pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    require(c>=a && c>=b);
    return c;
  }
}

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

contract SBC is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public _totalSupply;
	address public owner;
	
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
	mapping(address => uint256) freezes;
	
    event Burn(address indexed from, uint256 value);
	
    event Mint(address indexed from, uint256 value);
    
    event Freeze(address indexed from, uint256 value);
	
    event Unfreeze(address indexed from, uint256 value);
	
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    constructor(uint initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
        symbol = tokenSymbol;
        name = tokenName;
        decimals = decimalUnits;
        _totalSupply = initialSupply;
		owner = msg.sender;
        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _tokenOwner) public constant returns (uint balance) {
        return balances[_tokenOwner];
    }

    function allowance(address _tokenOwner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_tokenOwner][_spender];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
		require(tokens > 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
		require(tokens > 0); 
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != address(0));                                      // Prevent transfer to 0x0 address. Use burn() instead
		require(tokens > 0); 
        require(balances[from] >= tokens);                              // Check if the sender has enough
        require(allowed[from][msg.sender] >= tokens);                   // Check allowance
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);                   // Updates balance
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function freezeOf(address _tokenOwner) public constant returns (uint) {
        return freezes[_tokenOwner];
    }
    
	function freeze(address account, uint256 tokens) public returns (bool success) {
        require(msg.sender == owner);                                   // only owner
        require(balances[account] >= tokens);                           // Check if the sender has enough
		require(tokens > 0); 
        balances[account] = safeSub(balances[account], tokens);         // Subtract from the sender
        freezes[account] = safeAdd(freezes[account], tokens);           // Updates freeze
        emit Freeze(account, tokens);
        return true;
    }
	
	function unfreeze(address account, uint256 tokens) public returns (bool success) {
        require(msg.sender == owner);                                   // only owner
        require(freezes[account] >= tokens);                         // Check if the sender has enough
		require(tokens > 0); 
        freezes[account] = safeSub(freezes[account], tokens);     // Subtract from the sender
		balances[account] = safeAdd(balances[account], tokens);   // Updates balance
        emit Unfreeze(account, tokens);
        return true;
    }
    
    function burn(uint256 tokens) public returns (bool success) {
        require(msg.sender == owner);                                   // only owner
        require(balances[msg.sender] >= tokens);                        // Check if the sender has enough
		require(tokens > 0); 
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);   // Subtract from the sender
        _totalSupply = safeSub(_totalSupply, tokens);                   // Updates totalSupply
        emit Burn(msg.sender, tokens);
        return true;
    }

    function mint(uint256 tokens) public returns (bool success) {
        require(msg.sender == owner);                                   // only owner
        require(msg.sender != address(0));
        require(tokens > 0); 
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);   // Subtract from the sender
        _totalSupply = safeAdd(_totalSupply, tokens);                   // Updates totalSupply
        emit Mint(msg.sender, tokens);
        emit Transfer(address(0), msg.sender, tokens);
        return true;
    }
    
    
    function transferOwnership(address newOwner) public returns (bool success) {
        require(msg.sender == owner);                                   // only owner
        require(newOwner != address(0));
        require(msg.sender != newOwner);
        emit TransferOwnership(owner, newOwner);
        owner = newOwner;                                               // update owner
        return true;
    }
    
	function() public payable {
        revert();
    }
}