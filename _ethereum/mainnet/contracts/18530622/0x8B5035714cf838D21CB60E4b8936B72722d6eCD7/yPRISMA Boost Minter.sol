# @version 0.3.10

"""
@title yPRISMA Boost Minter
@license GNU AGPLv3
@author Yearn Finance
"""
from vyper.interfaces import ERC20

interface IYPRISMA:
    def delegate_mint(_recipient: address, _amount: uint256) -> uint256: nonpayable
    def ylocker() -> address: view

interface IYLOCKER:
    def proxy() -> address: view

interface IYPROXY:
    def collectTokensFromLocker(token: address, amount: uint256, recipient: address) -> uint256: nonpayable

event FeeSet:
    fee: uint256

event UpdateOperator:
    operator: indexed(address)

event RewardTokenSet:
    token: indexed(address)

yprisma: public(immutable(address))
ylocker: public(immutable(address))
prisma_vault: public(immutable(address))
fee: public(uint256)
operator: public(address)
proposed_operator: public(address)
reward_tokens: DynArray[address, 10]

@external
def __init__(_yprisma: address, _prisma_vault: address, _operator: address):
    yprisma = _yprisma
    ylocker = IYPRISMA(_yprisma).ylocker()
    prisma_vault = _prisma_vault
    self.operator = _operator

@external
def set_fee(_fee: uint256):
    assert msg.sender == self.operator
    assert _fee <= 10_000
    self.fee = _fee
    log FeeSet(_fee)

@external
def set_operator(_proposed_operator: address):
    assert msg.sender == self.operator
    self.proposed_operator = _proposed_operator

@external
def accept_operator():
    proposed_operator: address = self.proposed_operator
    assert msg.sender == proposed_operator
    self.operator = proposed_operator
    self.proposed_operator = empty(address)
    log UpdateOperator(proposed_operator)

@external
def getFeePct(
    claimant: address,
    receiver: address,
    amount: uint256,
    previous_amount: uint256,
    total_weekly_emissions: uint256
) -> uint256:
    return self.fee

@external
def set_reward_tokens(_token_addresses: DynArray[address, 10]):
    assert msg.sender == self.operator, "!authorized"
    self.reward_tokens = _token_addresses
    for token in _token_addresses:
        log RewardTokenSet(token)


@external
def delegatedBoostCallback(
    _claimant: address,
    _receiver: address,
    _amount: uint256,
    _adjusted_amount: uint256,
    _fee: uint256,
    _previous_amount: uint256,
    _total_weekly_emissions: uint256
) -> bool:
    """
    @notice Allow users to mint directly from a claim.
    """
    assert msg.sender == prisma_vault, "!authorized"
    assert _adjusted_amount > 0, "Nothing to claim"

    if _receiver != ylocker: # Don't mint if not locking to ylocker
        return False

    # Mint yPRISMA
    IYPRISMA(yprisma).delegate_mint(
        _claimant, 
        (_adjusted_amount / 10 ** 18) * 10 ** 18 # We must trim precision to match the actual lock amount
    )

    # Fetch any extra rewards earned by users
    for token in self.reward_tokens:
        amount: uint256 = ERC20(token).balanceOf(ylocker)
        if amount == 0:
            continue

        IYPROXY(
            IYLOCKER(ylocker).proxy()
        ).collectTokensFromLocker(token, amount, _claimant)

    return True