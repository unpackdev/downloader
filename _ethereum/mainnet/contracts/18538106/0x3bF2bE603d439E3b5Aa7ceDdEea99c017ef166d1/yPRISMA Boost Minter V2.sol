# @version 0.3.10

"""
@title yPRISMA Boost Minter V2
@license GNU AGPLv3
@author Yearn Finance
"""
from vyper.interfaces import ERC20

interface IYPRISMA:
    def delegate_mint(_recipient: address, _amount: uint256) -> uint256: nonpayable
    def ylocker() -> address: view

interface IYLOCKER:
    def proxy() -> address: view
    def governance() -> address: view

interface IYPROXY:
    def collectTokensFromLocker(token: address, amount: uint256, recipient: address) -> uint256: nonpayable

event FeesConfigured:
    fee: uint256
    discount: uint256
    threshold: uint256

event UpdateOperator:
    operator: indexed(address)

event RewardTokenSet:
    token: indexed(address)

PRECISION: constant(uint256) = 10_000
yprisma_staker: public(constant(address)) =     0x774a55C3Eeb79929fD445Ae97191228Ab39c4d0f
yprisma_lp_staker: public(constant(address)) =  0x6806D62AAdF2Ee97cd4BCE46BF5fCD89766EF246
yprisma: public(constant(address)) =            0xe3668873D944E4A949DA05fc8bDE419eFF543882
prisma_vault: public(constant(address)) =       0x06bDF212C290473dCACea9793890C5024c7Eb02c
ylocker: public(immutable(address))
fee: public(uint256)
discount: public(uint256)
threshold: public(uint256)
proposed_operator: public(address)
reward_tokens: public(DynArray[address, 10])

@external
def __init__(
    _fee: uint256,
    _discount: uint256,
    _threshold: uint256
):
    ylocker = IYPRISMA(yprisma).ylocker()
    self.fee = _fee
    self.discount = _discount

@external
def configure_fees(_fee: uint256, _discount: uint256, _threshold: uint256):
    assert (
        msg.sender == IYLOCKER(ylocker).governance() or 
        msg.sender == ylocker
    ), "!authorized"
    assert _fee <= PRECISION
    assert _discount <= PRECISION
    self.fee = _fee
    self.discount = _discount
    self.threshold = _threshold
    log FeesConfigured(_fee, _discount, _threshold)

@external
def set_reward_tokens(_token_addresses: DynArray[address, 10]):
    assert (
        msg.sender == IYLOCKER(ylocker).governance() or 
        msg.sender == ylocker
    ), "!authorized"
    self.reward_tokens = _token_addresses
    for token in _token_addresses:
        log RewardTokenSet(token)

@external
def getFeePct(
    claimant: address,
    receiver: address,
    amount: uint256,
    previous_amount: uint256,
    total_weekly_emissions: uint256
) -> uint256:

    if receiver == ylocker:
        return 0 # No fee for locks to Yearn

    threshold: uint256 = self.threshold
    if (
        ERC20(yprisma_staker).balanceOf(claimant) >= threshold or
        ERC20(yprisma_lp_staker).balanceOf(claimant) >= threshold or
        ERC20(yprisma).balanceOf(claimant) >= threshold
    ):
        return self.fee * (PRECISION - self.discount) / PRECISION

    return self.fee

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
        return True

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