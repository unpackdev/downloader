pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------
// Erc20 token interface
// ----------------------------------------------------------------------------
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
// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

}
// ----------------------------------------------------------------------------
// BaseToken
// ----------------------------------------------------------------------------
contract BaseToken is Token,SafeMath {
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply = 10*10**26;
    uint256 constant public decimals = 18;
    string constant public name = "ETCC";
    string constant public symbol = "ETCC";
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_value <= 0) revert('value must be greater than 0');
        if (balances[_from] < _value) revert('Insufficient Balance');
        if (balances[_to] + _value < balances[_to]) revert('has overflows'); 
        if (_value > allowed[_from][msg.sender]) revert('not allowed');   
        balances[_from] = SafeMath.safeSub(balances[_from], _value);      
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);        
        allowed[_from][msg.sender] = SafeMath.safeSub(allowed[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) returns (bool success){
        if (_value <= 0) revert('_value must be greater than 0');
        if (balances[msg.sender] < _value) revert('Insufficient balance');
        if (balances[_to] + _value < balances[_to]) revert('has overflows');
        balances[msg.sender] = SafeMath.safeSub(balances[msg.sender], _value);                    
        balances[_to] = SafeMath.safeAdd(balances[_to], _value);                          
        emit Transfer(msg.sender, _to, _value);     
        return true;
    }

    

    function balanceOf(address _owner) constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        if (_value <= 0) revert('_value must be greater than 0');
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    function allowance(address _owner, address _spender) constant returns (uint256) {
        return allowed[_owner][_spender];
    }

    
    constructor() public{
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
}