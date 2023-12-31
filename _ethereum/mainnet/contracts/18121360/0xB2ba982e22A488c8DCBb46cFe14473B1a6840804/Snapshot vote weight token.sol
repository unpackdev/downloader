# @version 0.3.7
"""
@title Snapshot vote weight token
@author 0xkorin, Yearn Finance
@license GNU AGPLv3
@notice
    Dummy ERC20 token for voting on Snapshot.
    Voting weight is represented by ERC20 balance.
    Management can update the contract that measures the voting weight.
"""

from vyper.interfaces import ERC20
implements: ERC20

interface Measure:
    def total_vote_weight() -> uint256: view
    def vote_weight(_account: address) -> uint256: view

management: public(address)
pending_management: public(address)
measure: public(Measure)

name: public(constant(String[29])) = "st-yETH snapshot voting power"
symbol: public(constant(String[12])) = "st-yETH-s"
decimals: public(constant(uint8)) = 18

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event SetMeasure:
    measure: indexed(address)

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

@external
def __init__(_measure: address):
    """
    @notice Constructor
    @param _measure Contract to measure voting weight by account
    """
    self.management = msg.sender
    self.measure = Measure(_measure)

    log SetManagement(msg.sender)
    log SetMeasure(_measure)
    log Transfer(empty(address), self, 0)

@external
@view
def totalSupply() -> uint256:
    """
    @notice Get total token supply, defined as the total vote weight. Calls underlying measure
    @return Total token supply
    """
    return self.measure.total_vote_weight()

@external
@view
def balanceOf(_account: address) -> uint256:
    """
    @notice Get account token balance, defined as the vote weight. Calls underlying measure
    @param _account Account to get token balance for
    @return Account token balance
    """
    return self.measure.vote_weight(_account)

@external
@view
def allowance(_account: address, _spender: address) -> uint256:
    return 0

@external
def transfer(_to: address, _value: uint256) -> bool:
    raise

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    raise

@external
def approve(_spender: address, _value: uint256) -> bool:
    raise

@external
def set_measure(_measure: address):
    """
    @notice Set new vote weight measurement contract
    @param _measure New vote weight measurement contract
    """
    assert msg.sender == self.management
    self.measure = Measure(_measure)
    log SetMeasure(_measure)

@external
def set_management(_management: address):
    """
    @notice 
        Set the pending management address.
        Needs to be accepted by that account separately to transfer management over
    @param _management New pending management address
    """
    assert msg.sender == self.management
    self.pending_management = _management
    log PendingManagement(_management)

@external
def accept_management():
    """
    @notice 
        Accept management role.
        Can only be called by account previously marked as pending management by current management
    """
    assert msg.sender == self.pending_management
    self.pending_management = empty(address)
    self.management = msg.sender
    log SetManagement(msg.sender)