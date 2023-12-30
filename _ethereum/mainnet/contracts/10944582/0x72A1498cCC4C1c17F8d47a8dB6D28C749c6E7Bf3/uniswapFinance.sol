pragma solidity ^0.4.26;

contract ERC20Interface{
    function totalSupply() public view returns (uint);
    
    function balanceOf(address tokenOwner) public view returns (uint balance);
        
    function allowance (address tokenOwner, address spender) public returns (uint remaining);
    
    function transfer(address _to, uint tokens) public returns (bool success);
             
    function approve(address spender, uint tokens) public returns (bool success);
    
    function transferFrom (address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

contract uniswapFinance is ERC20Interface, SafeMath{
    string private  name;
    string private symbol;
    uint8 public decimals;
   
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    function() public {
        name = "uniswap.finance";
        symbol = "UNFI";
        decimals = 18;
        _totalSupply = 50000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply); 
    }
        function totalSupply() public view returns(uint)
        {
            return _totalSupply - balances[address(0)];
        }
        
        function balanceOf(address tokenOwner) public view returns(uint)
        {
            return balances[tokenOwner];
        }
        
        function allowance (address tokenOwner, address spender) public  returns(uint remaining)
        {
            return allowed[tokenOwner][spender];
        }
        
        function approve(address spender, uint tokens) public returns (bool success) {
            allowed[msg.sender][spender] = tokens;
            emit Approval(msg.sender, spender, tokens);
            return true;
        }
        
        function transfer(address _to, uint tokens) public returns (bool success) {
        if (balances[msg.sender] >= tokens 
            && tokens > 0
            && balances[_to] + tokens > balances[_to]) {
            balances[msg.sender] -= tokens;
            balances[_to] += tokens;
            emit Transfer(msg.sender, _to, tokens);
            return true;
        } else {
            return false;
        }
        }
        function transferFrom(
        address _from,
        address _to,
        uint256 tokens
    ) public returns  (bool success) {
        if (balances[_from] >= tokens
            && allowed[_from][msg.sender] >= tokens
            && tokens > 0
            && balances[_to] + tokens > balances[_to]) {
            balances[_from] -= tokens;
            allowed[_from][msg.sender] -= tokens;
            balances[_to] += tokens;
            emit Transfer(_from, _to, tokens);
            return true;
        } else {
            return false;
        }
    }
        
       
    }