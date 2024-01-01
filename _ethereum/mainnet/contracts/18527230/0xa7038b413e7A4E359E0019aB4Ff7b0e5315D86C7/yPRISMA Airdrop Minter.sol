# @version 0.3.10

"""
@title yPRISMA Airdrop Minter
@license GNU AGPLv3
@author Yearn Finance
"""

interface IYPRISMA:
    def delegate_mint(_recipient: address, _amount: uint256) -> uint256: nonpayable
    def ylocker() -> address: view

ylocker: public(immutable(address))
yprisma: public(immutable(address))

CLAIM_CONTRACTS: public(constant(address[2])) = [
    0x3ea03249B4D68Be92a8eda027C5ac12e6E419BEE, # 52 week lock (veCRV)
    0x2C533357664d8750e5F851f39B2534147F5578af, # 26 week lock (early users)
]

@external
def __init__(_yprisma: address):
    yprisma = _yprisma
    ylocker = IYPRISMA(_yprisma).ylocker()

@external
def claimCallback(_claimant: address, _receiver: address, _amount: uint256) -> bool:
    """
    @dev Allow callbacks from claim contracts.
    """
    assert msg.sender in CLAIM_CONTRACTS, "!authorized"
    assert _receiver == ylocker, "invalid receiver"
    IYPRISMA(yprisma).delegate_mint(_claimant, _amount * 10 ** 18) # Multiply amount by lockToTokenRatio
    return True