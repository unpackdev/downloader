pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view   returns (uint256);
    function transfer(address to, uint256 value) public  returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IGC is ERC20 {

    using SafeMath for uint256;

    address public owner;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    string public name = "IGC";
    string public constant symbol = "IGC";
    uint public constant decimals = 18;


    uint stopped;
    
    uint256 public totalSupply = 990000000*(10**18) ;


    modifier stoppable {
        assert(stopped == 0);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    // 
    function IGC() public {

        owner = msg.sender;   
        balances[owner] =  totalSupply ;       
    }

    function setStop(uint8 num) public onlyOwner  {
        stopped = num;
    }

    
    function transferOwnership(address _newOwner) onlyOwner public {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function balanceOf(address _owner)  public view  returns (uint256) {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) stoppable  public returns (bool success) {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, uint256 _amount) stoppable public returns (bool success) {
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        emit Transfer(_from, msg.sender, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) stoppable public returns (bool success) {
        if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }



    function allowance(address _owner, address _spender)  constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
}