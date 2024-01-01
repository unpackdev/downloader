# @version 0.3.10

"""
@title yPRISMA Legacy Minter
@notice Allow users to mint yPRISMA from legacy tokens.
@license GNU AGPLv3
@author Yearn Finance
"""
from vyper.interfaces import ERC20

interface IYPRISMA:
    def delegate_mint(_recipient: address, _amount: uint256) -> uint256: nonpayable

yprisma: public(immutable(address))
legacy_token: public(immutable(address))

@external
def __init__(_yprisma: address, _legacy_token: address):
    yprisma = _yprisma
    legacy_token = _legacy_token

@external
def redeem(_amount: uint256 = max_value(uint256), _recipient: address = msg.sender) -> uint256:
    """
    @notice Allow users of legacy token to mint to new token 1:1
    """
    amount: uint256 = _amount
    if amount == max_value(uint256):
        amount = ERC20(legacy_token).balanceOf(msg.sender)
    assert amount > 0
    assert ERC20(legacy_token).transferFrom(msg.sender, self, amount)  # dev: burn tokens
    return IYPRISMA(yprisma).delegate_mint(_recipient, amount)