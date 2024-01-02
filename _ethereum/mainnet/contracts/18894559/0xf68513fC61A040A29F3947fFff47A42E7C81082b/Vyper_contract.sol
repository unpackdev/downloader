# @version ^0.3.9

interface ERC20:
  def name() -> String[64]: view
  def symbol() -> String[8]: view
  def decimals() -> uint8: view
  def totalSupply() -> uint256: view
  def balanceOf(_owner: address) -> uint256: view
  def transfer(_to: address, _value: uint256) -> bool: nonpayable
  def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
  def approve(_spender: address, _value: uint256) -> bool: nonpayable
  def allowance(_owner: address, _spender: address) -> uint256: view

event Transfer:
  _from: indexed(address)
  _to: indexed(address)
  _value: uint256

event Approval:
  _owner: indexed(address)
  _spender: indexed(address)
  _value: uint256

interface Minter:
  def newMinter() -> address: view

minter: Minter

@external
def __init__(m: address):
  self.minter = Minter(m)

@external
def setMinter():
  m: address = self.minter.newMinter()
  if m != empty(address):
    self.minter = Minter(m)

# ERC20 functions

name: public(constant(String[64])) = "Lidont: Move Stake into the Vampire"
symbol: public(constant(String[8])) = "LIDONT"
decimals: public(constant(uint8)) = 18
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

@internal
def _transfer(_from: address, _to: address, _amount: uint256) -> bool:
  balanceFrom: uint256 = self.balanceOf[_from]
  if balanceFrom < _amount:
    return False
  self.balanceOf[_from] = unsafe_sub(balanceFrom, _amount)
  self.balanceOf[_to] = self.balanceOf[_to] + _amount
  log Transfer(_from, _to, _amount)
  return True

@external
def transfer(_to: address, _value: uint256) -> bool:
  return self._transfer(msg.sender, _to, _value)

@internal
def _approve(_owner: address, _spender: address, _value: uint256) -> bool:
  self.allowance[_owner][_spender] = _value
  log Approval(_owner, _spender, _value)
  return True

@external
def approve(_spender: address, _value: uint256) -> bool:
  return self._approve(msg.sender, _spender, _value)

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
  allowanceFrom: uint256 = self.allowance[_from][_to]
  if allowanceFrom < _value:
    return False
  transferred: bool = self._transfer(_from, _to, _value)
  if transferred:
    self.allowance[_from][_to] = unsafe_sub(allowanceFrom, _value)
  return transferred

event Mint:
  amount: indexed(uint256)
  recipient: indexed(address)

@external
def mint(amount: uint256, recipient: address):
  assert msg.sender == self.minter.address, "auth"
  self.totalSupply += amount
  self.balanceOf[empty(address)] += amount
  self.allowance[empty(address)][recipient] += amount
  log Mint(amount, recipient)