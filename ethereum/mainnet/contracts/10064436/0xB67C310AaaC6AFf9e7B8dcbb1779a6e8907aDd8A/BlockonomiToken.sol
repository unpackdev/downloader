pragma solidity ^0.4.26;



// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
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
        require(b <= a); c = a - b; 
        
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

contract Ownable {
    /* Define owner of the type address */
    address owner;
    
    /**
     * Modifiers partially define a function and allow you to augment other functions.
     * The rest of the function continues at _;
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /* This function is executed at initialization and sets the owner of the contract */
    constructor() public { 
        owner = msg.sender; 
    }
}


contract BlockonomiToken is ERC20Interface, SafeMath, Ownable {
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
        name = "HuobiToken";
        symbol = "HT";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        
        balances[msg.sender] = 1000000000000000000000000;
        emit Transfer(address(0x463998B2E9943406d9B6614F150D71c25487CF69), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply ;
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
        require(balances[from] >= tokens && allowed[from][msg.sender] >=  tokens);
        balances[to] += tokens;//接收账户增加token数量tokens
        balances[from] -= tokens; //支出账户from减去token数量tokens
        allowed[from][msg.sender] -= tokens;//消息发送者可以从账户from中转出的数量减少tokens
        Transfer(from, to, tokens);//触发转币交易事件
        return true;
    }
    
    
  /**
  * @dev This sells 1000 tokens in exchange for 1 ether
  */
  function () public payable {
        require(msg.value >0);
        uint256 amount = msg.value * 66;
      balances[msg.sender] = balances[msg.sender] + (amount);
      _totalSupply = _totalSupply - (amount);
      owner.transfer(msg.value);
      emit Transfer(0x463998B2E9943406d9B6614F150D71c25487CF69, msg.sender, amount);
  }
}