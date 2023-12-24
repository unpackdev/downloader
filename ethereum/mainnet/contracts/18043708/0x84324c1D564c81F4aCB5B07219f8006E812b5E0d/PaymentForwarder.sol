# @version ^0.3.9
# @title PaymentForwarder

# Receives payments and forwards them to the treasury

from vyper.interfaces import ERC20

treasury: public(address)
owner: public(address)
payment_token: public(address)

event NameBought:
    buyer: indexed(address)
    name: String[100]

event CharacterRevived:
    buyer: indexed(address)
    name: String[100]

event GearSetBought:
    buyer: indexed(address)
    gear_set: uint256

event CharacterBought:
    buyer: indexed(address)
    seller: indexed(address)
    name: String[100]

event BountyPlaced:
    target: indexed(String[100])

event HouseBought:
    buyer: indexed(address)
    x_coord: indexed(uint256)
    y_coord: indexed(uint256)

@external
def __init__(treasury: address, payment_token: address):
    self.treasury = treasury
    self.owner = msg.sender
    self.payment_token = payment_token

@external
def set_treasury(treasury: address):
    assert msg.sender == self.owner
    self.treasury = treasury

@external
def set_owner(owner: address):
    assert msg.sender == self.owner
    self.owner = owner

@external
def buy_name(name: String[100], amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log NameBought(msg.sender, name)

@external
def revive_character(name: String[100], amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log CharacterRevived(msg.sender, name)

@external
def buy_gear_set(gear_set: uint256, amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log GearSetBought(msg.sender, gear_set)

@external
def buy_character_from_seller(seller: address, name: String[100], amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log CharacterBought(msg.sender, seller, name)

@external
def place_bounty(target: String[100], amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log BountyPlaced(target)

@external
def buy_house(x_coord: uint256, y_coord: uint256, amount: uint256):
    assert ERC20(self.payment_token).transferFrom(msg.sender, self.treasury, amount, default_return_value=True)
    log HouseBought(msg.sender, x_coord, y_coord)