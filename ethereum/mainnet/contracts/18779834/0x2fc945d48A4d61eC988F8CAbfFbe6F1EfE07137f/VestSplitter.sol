# @version 0.3.10
"""
@title VestSplitter
@author Curve Finance
@license MIT
@notice Split VestingEscrow for a distribution of users, and accepts donations and top-ups.
        Made originally to compensate victims of Vyper hack, but can be used for other purposes.
"""

from vyper.interfaces import ERC20


interface VestingEscrow:
    def claim(): nonpayable
    def balanceOf(user: address) -> uint256: view


event Claim:
    recipient: indexed(address)
    claimed: uint256


TOKEN: public(immutable(ERC20))
vest: public(VestingEscrow)
ADMIN: public(immutable(address))

fractions: public(HashMap[address, uint256])
total_fraction: public(uint256)
finalized: public(bool)

last_balance: public(uint256)
total_granted: public(uint256)
claimed: public(HashMap[address, uint256])


@external
def __init__(token: ERC20):
    TOKEN = token
    ADMIN = msg.sender  # Only needed before the distribution is finalized


@external
def set_vest(vest: VestingEscrow):
    assert msg.sender == ADMIN, "Access"
    assert self.vest == empty(VestingEscrow), "Vest already set"
    self.vest = vest


@external
def save_distribution(users: DynArray[address, 200], fractions: DynArray[uint256, 200]):
    assert msg.sender == ADMIN, "Access"
    assert not self.finalized, "Distribution is finalized already"

    for i in range(200):
        if i >= len(users):
            break
        user: address = users[i]
        f_old: uint256 = self.fractions[user]
        f: uint256 = fractions[i]

        self.fractions[user] = f
        self.total_fraction = self.total_fraction + f - f_old


@external
def finalize_distribution():
    assert msg.sender == ADMIN, "Access"
    self.finalized = True


@external
@nonreentrant('lock')
def claim(user: address = msg.sender, use_vest: bool = True):
    vest: VestingEscrow = self.vest
    if use_vest and vest != empty(VestingEscrow) and vest != VestingEscrow(self):
        vest.claim()
    total_granted: uint256 = self.total_granted + (TOKEN.balanceOf(self) - self.last_balance)
    self.total_granted = total_granted

    total_for_user: uint256 = total_granted * self.fractions[user] / self.total_fraction
    to_send: uint256 = total_for_user - self.claimed[user]
    self.claimed[user] = total_for_user
    TOKEN.transfer(user, to_send)

    self.last_balance = TOKEN.balanceOf(self)

    log Claim(user, to_send)


@external
@view
def balanceOf(user: address, use_vest: bool = True) -> uint256:
    total_granted: uint256 = self.total_granted
    vest: VestingEscrow = self.vest
    if use_vest and vest != empty(VestingEscrow) and vest != VestingEscrow(self):
        total_granted += vest.balanceOf(self)
    total_granted = total_granted + TOKEN.balanceOf(self) - self.last_balance
    total_for_user: uint256 = total_granted * self.fractions[user] / self.total_fraction
    return total_for_user - self.claimed[user]