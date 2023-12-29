pragma solidity ^0.4.4;


contract Token {


    function totalSupply() constant returns (uint256 supply) {}


    function balanceOf(address _owner) constant returns (uint256 balance) {}


    function transfer(address _to, uint256 _value) returns (bool success) {}


    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}


    function approve(address _spender, uint256 _value) returns (bool success) {}


    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
   
}

contract FiatContract {
  function ETH(uint _id) constant returns (uint256);
  function USD(uint _id) constant returns (uint256);
  function EUR(uint _id) constant returns (uint256);
  function GBP(uint _id) constant returns (uint256);
  function updatedAt(uint _id) constant returns (uint);
}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function getPrice() public returns(uint256 price) {
            uint256 oneCent = fiatContractAddress.EUR(0);
            return price;
    }    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
    uint256 public price;
    FiatContract public fiatContractAddress;
}


contract ERC20Token is StandardToken {

    function () {
        throw;
    }

    string public name;                   
    uint8 public decimals;
    string public symbol;                 
    string public version = 'H1.0';       


    function ERC20Token() {

         balances[msg.sender]= 10000000000;
         totalSupply= 9999999999;
         name= 'KRX';
         decimals= 1;
         symbol= 'KRX';
         price = 10000000000000000;
         fiatContractAddress = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);

    }
    
    event Burn(address indexed burner, uint256 value);


  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);


    balances[_who] = balances[_who]-_value;
    totalSupply = totalSupply - _value;
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

   
}