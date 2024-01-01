// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a && c >= b);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0);
    c = a / b;
  }
}

contract PsiToken {
  using SafeMath for uint256;
  
  // --- public data members

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  address payable public owner;
  
  mapping (address => uint256) public balanceOf;
  mapping (address => uint256) public freezeOf;
  mapping (address => mapping (address => uint256)) public allowance;

  // --- events

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value);
  
  event Burn(address indexed from, uint256 value);
  
  event Freeze(address indexed from, uint256 value);
  
  event Unfreeze(address indexed from, uint256 value);

  // --- constructor

  constructor(
      string memory _name,
      string memory _symbol,
      uint8 _decimals,
      uint256 _totalSupply) {
    require(_totalSupply > 0);
    require(_decimals >= 0);
    balanceOf[msg.sender] = _totalSupply;
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupply;
    decimals = _decimals;
    owner = payable(msg.sender);
  }

  // --- ERC-20 functions

  function transfer(
      address _to,
      uint256 _value) external returns (bool success) {
    require(_to != address(0x0));
    require(_value > 0); 
    require(balanceOf[msg.sender] >= _value);
    require(balanceOf[_to] + _value > balanceOf[_to]);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(
      address _from,
      address _to,
      uint256 _value) external returns (bool success) {
    require(_to != address(0x0));
    require(_value > 0); 
    require(balanceOf[_from] >= _value);
    require(balanceOf[_to] + _value >= balanceOf[_to]);
    require(_value <= allowance[_from][msg.sender]);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(
      address _spender,
      uint256 _value) external returns (bool success) {
    require(_value >= 0);
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  // --- other functions - burn, freeze, unfreeze

  function burn(uint256 _value) external returns (bool success) {
    require(balanceOf[msg.sender] >= _value);
    require(_value > 0);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    return true;
  }
  
  function freeze(uint256 _value) external returns (bool success) {
    require(balanceOf[msg.sender] >= _value);
    require(_value > 0);
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);
    emit Freeze(msg.sender, _value);
    return true;
  }
  
  function unfreeze(uint256 _value) external returns (bool success) {
    require(freezeOf[msg.sender] >= _value);
    require(_value > 0);
    freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
    emit Unfreeze(msg.sender, _value);
    return true;
  }

  // --- accept and withdraw ETH

  receive() external payable { }

  function withdrawEther(uint256 _value) external {
    require(msg.sender == owner);
    owner.transfer(_value);
  }
}