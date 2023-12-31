# @version 0.3.9
"""
@title Curve Bridge Ownerhip Proxy
@license MIT
@author Curve Finance
"""

interface Bridge:
    def set_delay(_delay: uint256): nonpayable
    def set_limit(_limit: uint256): nonpayable
    def set_killed(_is_killed: bool): nonpayable
    def commit_transfer_ownership(addr: address): nonpayable
    def accept_transfer_ownership(): nonpayable


event CommitAdmins:
    ownership_admin: address
    emergency_admin: address

event ApplyAdmins:
    ownership_admin: address
    emergency_admin: address


ownership_admin: public(address)
emergency_admin: public(address)

future_ownership_admin: public(address)
future_emergency_admin: public(address)


@external
def __init__(_ownership_admin: address, _emergency_admin: address):
    self.ownership_admin = _ownership_admin
    self.emergency_admin = _emergency_admin


@external
@nonreentrant('lock')
def set_killed(_bridge: address, _is_killed: bool):
    assert msg.sender in [self.ownership_admin, self.emergency_admin], "Access denied"

    Bridge(_bridge).set_killed(_is_killed)


@external
@nonreentrant('lock')
def set_limit(_bridge: address, _limit: uint256):
    assert msg.sender in [self.ownership_admin], "Access denied"

    Bridge(_bridge).set_limit(_limit)


@external
@nonreentrant('lock')
def set_delay(_bridge: address, _delay: uint256):
    assert msg.sender in [self.ownership_admin], "Access denied"

    Bridge(_bridge).set_delay(_delay)


@external
def commit_set_admins(_o_admin: address, _e_admin: address):
    """
    @notice Set ownership admin to `_o_admin` and emergency admin to `_e_admin`
    @param _o_admin Ownership admin
    @param _e_admin Emergency admin
    """
    assert msg.sender == self.ownership_admin, "Access denied"

    self.future_ownership_admin = _o_admin
    self.future_emergency_admin = _e_admin

    log CommitAdmins(_o_admin, _e_admin)


@external
def accept_set_admins():
    """
    @notice Apply the effects of `commit_set_admins`
    @dev Only callable by the new owner admin
    """
    assert msg.sender == self.future_ownership_admin, "Access denied"

    e_admin: address = self.future_emergency_admin
    self.ownership_admin = msg.sender
    self.emergency_admin = e_admin

    log ApplyAdmins(msg.sender, e_admin)


@external
@nonreentrant('lock')
def commit_transfer_ownership(_bridge: address, new_owner: address):
    assert msg.sender == self.ownership_admin, "Access denied"
    Bridge(_bridge).commit_transfer_ownership(new_owner)


@external
@nonreentrant('lock')
def accept_transfer_ownership(_bridge: address):
    Bridge(_bridge).accept_transfer_ownership()