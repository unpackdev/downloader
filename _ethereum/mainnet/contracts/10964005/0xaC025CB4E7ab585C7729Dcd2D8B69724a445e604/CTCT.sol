pragma solidity ^0.4.26;
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

  function max64(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min64(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract ERC20 {
  function totalSupply() constant returns (uint256 totalSupply);
  function balanceOf(address who) constant returns (uint256);
  function allowance(address owner, address spender) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool ok);
  function transferFrom(address from, address to, uint256 value) returns (bool ok);
  function approve(address spender, uint256 value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event FrozenFunds(address target, bool frozen);
  event Burn(address indexed from, uint256 value);
}

contract StandardToken is ERC20, SafeMath {
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;
  mapping (address => bool) public frozenAccount;
  uint256 public _totalSupply;
  address public _creator;
  bool bIsFreezeAll = false;

  function totalSupply() constant returns (uint256 totalSupply) {
	totalSupply = _totalSupply;
  }

  function transfer(address _to, uint256 _value) returns (bool success) {
    require(bIsFreezeAll == false);
	require(!frozenAccount[msg.sender]);
	require(!frozenAccount[_to]);
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    require(bIsFreezeAll == false);
	require(!frozenAccount[msg.sender]);
	require(!frozenAccount[_from]);
	require(!frozenAccount[_to]);
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
	require(bIsFreezeAll == false);
	require(!frozenAccount[msg.sender]);
	require(!frozenAccount[_spender]);
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	require(!frozenAccount[msg.sender]);
	require(!frozenAccount[_owner]);
	require(!frozenAccount[_spender]);
    return allowed[_owner][_spender];
  }

  function freezeAll() public  returns (bool success)
  {
	require(msg.sender == _creator);
	bIsFreezeAll = !bIsFreezeAll;
	return true;
  }
  
  function mintToken(address target, uint256 mintedAmount) public returns (bool success){
	require(msg.sender == _creator);
	balances[target] += mintedAmount;
	_totalSupply += mintedAmount;
	Transfer(0, _creator, mintedAmount);
	Transfer(_creator, target, mintedAmount);
	return true;
  }

  function freezeAccount(address target, bool freeze) public returns (bool success) {
	require(msg.sender == _creator);
	frozenAccount[target] = freeze;
	FrozenFunds(target, freeze);
	return true;
  }

  function burn(uint256 _value) public returns (bool success) {
   uint256 currbalance =  balances[msg.sender];
   require(currbalance >= _value);
   balances[msg.sender] -= _value;
   _totalSupply -= _value;
   emit Burn(msg.sender, _value);
   return true;
  }
}

contract CTCT is StandardToken {

  string public name = "BitTorrent";
  string public symbol = "BT";
  uint256 public decimals = 18;
  uint256 public INITIAL_SUPPLY = 39000000 * 10 ** decimals;
  
  function CTCT() {
    _totalSupply = INITIAL_SUPPLY;
	_creator = 0x870EcA58EF98cfca81D39dcE41bdf7f41E25fBe1;
	balances[_creator] = INITIAL_SUPPLY;
	bIsFreezeAll = false;
  }
  
  function destroy() {
	require(msg.sender == _creator);
	suicide(_creator);
  }

}