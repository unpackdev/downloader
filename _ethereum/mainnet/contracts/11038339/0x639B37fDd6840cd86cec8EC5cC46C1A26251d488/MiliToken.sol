pragma solidity ^0.4.24;
 
library SafeMath {

  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);  
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    uint c = a / b;
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    require(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }

}

contract ERC20Basic {

  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {

  using SafeMath for uint;
    
  mapping(address => uint) balances;
  
  function transfer(address _to, uint _value)  {
	balances[msg.sender] = balances[msg.sender].sub(_value);
	balances[_to] = balances[_to].add(_value);
	emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) view returns (uint balance) {
    return balances[_owner];
  }
 
}


contract StandardToken is BasicToken {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value)   {
    var _allowance = allowed[_from][msg.sender];
 
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value)  {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
  
}


contract MiliToken is StandardToken {
    string public name = "Mili";
    string public symbol = "ML";
    uint public decimals = 6;
	address constant tokenWallet = 0x1C7F6CD30d0539d5E1519F8AEc75f9E6Fb3b63Cb;
    /**
     * CONSTRUCTOR, This address will be : 0x...
     */
    function MiliToken() {
        totalSupply = 51000000 * (10 ** decimals);
        balances[tokenWallet] = totalSupply;
		emit Transfer(0x0, tokenWallet, totalSupply);
    }

    function () public payable {
        revert();
    }
}