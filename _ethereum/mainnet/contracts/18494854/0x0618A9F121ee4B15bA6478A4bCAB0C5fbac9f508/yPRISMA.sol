# @version 0.3.10

"""
@title yPRISMA
@author Yearn Finance
"""

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

event UpdateSweepRecipient:
    sweep_recipient: indexed(address)

LOCKER: public(immutable(address))
TOKEN: public(immutable(address))
name: public(immutable(String[32]))
symbol: public(immutable(String[32]))
decimals: public(immutable(uint8))

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
sweep_recipient: public(address)

claimer: public(HashMap[address, uint256])
CLAIM_CONTRACTS: public(immutable(address[2]))


@external
def __init__(_name: String[32], _symbol: String[32], _token: address, _locker: address):
    name = _name
    symbol = _symbol
    decimals = 18
    TOKEN = _token
    LOCKER = _locker
    self.sweep_recipient = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52
    CLAIM_CONTRACTS = [
        0xd49d86B001Fe35bc745Bc6E467B3cc18Cb14b817, # 13 weeks
        0x4Bd112ffF755C24C103AdF5879ee914781b99c62, # 52 weeks
    ]

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
     @dev Transfer tokens from one address to another.
     @param _from address The address which you want to send tokens from
     @param _to address The address which you want to transfer to
     @param _value uint256 the amount of tokens to be transferred
    """
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True
        
@internal
def _mint(_to: address, _value: uint256):
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(empty(address), _to, _value)

@external
def mint(_amount: uint256 = max_value(uint256), _recipient: address = msg.sender) -> uint256:
    """
    @notice Lock any amount of the underlying token to mint yTOKEN 1 to 1.
    @param _amount The desired amount of tokens to lock / yTOKENs to mint.
    @param _recipient The address which minted yTOKENS should be received at.
    """
    assert _recipient not in [self, empty(address)]
    amount: uint256 = _amount
    if amount == max_value(uint256):
        amount = ERC20(TOKEN).balanceOf(msg.sender)
    assert amount > 0
    assert ERC20(TOKEN).transferFrom(msg.sender, LOCKER, amount)  # dev: no allowance
    self._mint(_recipient, amount)
    return amount

@external
def claimCallback(_claimant: address, _amount: uint256) -> bool:
    """
    @dev Allow callbacks from claim contracts.
    """
    assert msg.sender in CLAIM_CONTRACTS, "!authorized"
    self._mint(_claimant, _amount * 10 ** 18) # Multiply amount by lockToTokenRatio
    return True

@external
def set_sweep_recipient(_proposed_recipient: address):
    assert msg.sender == self.sweep_recipient
    self.sweep_recipient = _proposed_recipient
    log UpdateSweepRecipient(_proposed_recipient)

@external
def sweep(_token: address, _amount: uint256 = max_value(uint256)):
    assert msg.sender == self.sweep_recipient
    amount: uint256 = _amount
    if amount == max_value(uint256):
        amount = ERC20(_token).balanceOf(self)
    assert amount > 0
    assert ERC20(_token).transfer(self.sweep_recipient, amount, default_return_value=True)