# @version 0.3.7
"""
@title yDiscount
@author Yearn Finance
@license AGPLv3
@notice
    Allow contributors to buy locked YFI at a discount.
    Once a month, yBudget gives allowances to teams based on their budget/revenue.
    Teams can allocate those allowances to their individual contributors, up to their salary.
    Contributors can choose to exercise (part of) their allowance to buy YFI at a discount.
    The YFI is added to their veYFI lock and the discount depends on the remaining duration of the lock.
    Alternatively contributors have the option to delegate their discount to a third party for a fixed discount.
"""

from vyper.interfaces import ERC20

struct LockedBalance:
    amount: uint256
    end: uint256

struct LatestRoundData:
    round_id: uint80
    answer: int256
    started: uint256
    updated: uint256
    answered_round: uint80

interface VotingEscrow:
    def locked(_account: address) -> LockedBalance: view
    def modify_lock(_amount: uint256, _unlock_time: uint256, _account: address) -> LockedBalance: nonpayable

interface ChainlinkOracle:
    def latestRoundData() -> LatestRoundData: view
    def decimals() -> uint256: view

interface DiscountCallback:
    def delegated(_lock: address, _account: address, _amount_spent: uint256, _amount_locked: uint256): nonpayable

yfi: public(immutable(ERC20))
veyfi: public(immutable(VotingEscrow))
chainlink_oracle: public(immutable(ChainlinkOracle))
management: public(immutable(address))

month: public(uint256)
expiration: public(uint256)
team_allowances: HashMap[address, uint256] # team -> packed allowance
contributor_allowances: HashMap[address, uint256] # contributor -> packed allowance

SCALE: constant(uint256) = 10**18
PRICE_DISCOUNT_SLOPE: constant(uint256) = 245096 * 10**10
PRICE_DISCOUNT_BIAS: constant(uint256) = 9019616 * 10**10
DELEGATE_DISCOUNT: constant(uint256) = 10**17

ALLOWANCE_EXPIRATION_TIME: constant(uint256) = 30 * 24 * 60 * 60
ORACLE_STALE_TIME: constant(uint256) = 2 * 60 * 60
WEEK: constant(uint256) = 7 * 24 * 60 * 60
MIN_LOCK_WEEKS: constant(uint256) = 4
DELEGATE_MIN_LOCK_WEEKS: constant(uint256) = 104
CAP_DISCOUNT_WEEKS: constant(uint256) = 208

ALLOWANCE_MASK: constant(uint256) = 2**192 - 1
MONTH_SHIFT: constant(int128) = -192
MONTH_MASK: constant(uint256) = 2**64 - 1

event NewMonth:
    month: indexed(uint256)
    expiration: uint256

event TeamAllowance:
    team: indexed(address)
    allowance: uint256
    month: uint256
    expiration: uint256

event ContributorAllowance:
    team: indexed(address)
    contributor: indexed(address)
    allowance: uint256
    month: uint256
    expiration: uint256

event Buy:
    contributor: indexed(address)
    amount_in: uint256
    amount_out: uint256
    discount: uint256
    lock: address

@external
def __init__(_yfi: address, _veyfi: address, _chainlink_oracle: address, _management: address):
    """
    @notice Constructor
    @param _yfi YFI address
    @param _veyfi veYFI address
    @param _chainlink_oracle Chainlink oracle address
    @param _management Management address
    """
    yfi = ERC20(_yfi)
    veyfi = VotingEscrow(_veyfi)
    chainlink_oracle = ChainlinkOracle(_chainlink_oracle)
    management = _management
    assert ChainlinkOracle(_chainlink_oracle).decimals() == 18
    assert ERC20(_yfi).approve(_veyfi, max_value(uint256), default_return_value=True)

@external
@view
def team_allowance(_team: address) -> uint256:
    """
    @notice Get available allowance for a particular team
    @param _team Team to query allowance for
    @return Allowance amount
    """
    allowance: uint256 = 0
    month: uint256 = 0
    allowance, month = self._unpack_allowance(self.team_allowances[_team])
    if month != self.month or block.timestamp >= self.expiration:
        return 0
    return allowance

@external
@view
def contributor_allowance(_contributor: address) -> uint256:
    """
    @notice Get available allowance for a particular contributor
    @param _contributor Contributor to query allowance for
    @return Allowance amount
    """
    allowance: uint256 = 0
    month: uint256 = 0
    allowance, month = self._unpack_allowance(self.contributor_allowances[_contributor])
    if month != self.month or block.timestamp >= self.expiration:
        return 0
    return allowance

@external
def set_team_allowances(_teams: DynArray[address, 256], _allowances: DynArray[uint256, 256], _new_month: bool = True):
    """
    @notice Set new allowance for multiple teams
    @param _teams Teams to set allowances for
    @param _allowances Allowance amounts
    @param _new_month
        True: trigger a new month, invalidating previous allowances for all teams and contributors
        False: modify allowances for current month
    """
    assert msg.sender == management
    assert len(_teams) == len(_allowances)
    
    month: uint256 = self.month
    expiration: uint256 = 0
    if _new_month:
        month += 1
        expiration = block.timestamp + ALLOWANCE_EXPIRATION_TIME
        self.month = month
        self.expiration = expiration
        log NewMonth(month, expiration)
    else:
        expiration = self.expiration
        assert expiration > block.timestamp

    for i in range(256):
        if i == len(_teams):
            break
        assert _teams[i] != empty(address)
        self.team_allowances[_teams[i]] = self._pack_allowance(_allowances[i], month)
        log TeamAllowance(_teams[i], _allowances[i], month, expiration)

@external
def set_contributor_allowances(_contributors: DynArray[address, 256], _allowances: DynArray[uint256, 256]):
    """
    @notice Allocate team allowance to contributors
    @param _contributors Contributors to allocate allowances to
    @param _allowances Allowance amounts
    """
    assert len(_contributors) == len(_allowances)

    team_allowance: uint256 = 0
    month: uint256 = 0
    team_allowance, month = self._unpack_allowance(self.team_allowances[msg.sender])
    assert team_allowance > 0
    assert month == self.month and self.expiration > block.timestamp, "allowance expired"

    for i in range(256):
        if i == len(_contributors):
            break
        assert _contributors[i] != empty(address)
        if _allowances[i] == 0:
            continue

        team_allowance -= _allowances[i]
        contributor_allowance: uint256 = 0
        contributor_month: uint256 = 0
        contributor_allowance, contributor_month = self._unpack_allowance(self.contributor_allowances[_contributors[i]])
        if contributor_month != month:
            contributor_allowance = 0
        contributor_allowance += _allowances[i]

        self.contributor_allowances[_contributors[i]] = self._pack_allowance(contributor_allowance, month)
        log ContributorAllowance(msg.sender, _contributors[i], contributor_allowance, month, self.expiration)

    self.team_allowances[msg.sender] = self._pack_allowance(team_allowance, month)

@internal
@view
def _spot_price() -> uint256:
    data: LatestRoundData = chainlink_oracle.latestRoundData()
    assert block.timestamp < data.updated + ORACLE_STALE_TIME
    return convert(data.answer, uint256)

@external
@view
def spot_price() -> uint256:
    """
    @notice Get current YFI spot price in 18 decimals
    """
    return self._spot_price()

@internal
@view
def _discount(_account: address) -> (uint256, uint256):
    locked: LockedBalance = veyfi.locked(_account)
    assert locked.amount > 0
    weeks: uint256 = min(locked.end / WEEK - block.timestamp / WEEK, CAP_DISCOUNT_WEEKS)
    return weeks, PRICE_DISCOUNT_BIAS + PRICE_DISCOUNT_SLOPE * weeks

@external
@view
def discount(_account: address) -> uint256:
    """
    @notice Get contributor discount in 18 decimals
    @param _account Account to query discount for
    """
    weeks: uint256 = 0
    discount: uint256 = 0
    weeks, discount = self._discount(_account)
    return discount

@internal
@view
def _preview(_lock: address, _amount_in: uint256, _delegate: bool) -> (uint256, uint256):
    locked: LockedBalance = veyfi.locked(_lock)
    assert locked.amount > 0

    weeks: uint256 = 0
    discount: uint256 = 0
    weeks, discount = self._discount(_lock)
    price: uint256 = self._spot_price()
    if _delegate:
        assert weeks >= DELEGATE_MIN_LOCK_WEEKS, "delegate lock too short"
        discount = DELEGATE_DISCOUNT
    else:
        assert weeks >= MIN_LOCK_WEEKS, "lock too short"
    price = price * (SCALE - discount) / SCALE
    return _amount_in * SCALE / price, discount

@external
@view
def preview(_lock: address, _amount_in: uint256, _delegate: bool) -> uint256:
    """
    @notice Preview a YFI purchase
    @param _lock Account that owns the lock
    @param _amount_in Amount of ETH to spend
    @param _delegate False: lock belongs to contributor, True: lock belongs to a third party
    """
    amount: uint256 = 0
    discount: uint256 = 0
    amount, discount = self._preview(_lock, _amount_in, _delegate)
    return amount

@external
@payable
def buy(_min_locked: uint256, _lock: address = msg.sender, _callback: address = empty(address)) -> uint256:
    """
    @notice Buy YFI at a discount
    @param _min_locked Minimum amount of YFI to be locked
    @param _lock Owner of the lock to add to
    @param _callback Contract to call after adding to the lock
    @return Amount of YFI added to lock
    """
    assert msg.value > 0

    allowance: uint256 = 0
    month: uint256 = 0
    allowance, month = self._unpack_allowance(self.contributor_allowances[msg.sender])
    assert allowance > 0
    assert month == self.month and self.expiration > block.timestamp, "allowance expired"
    
    allowance -= msg.value
    self.contributor_allowances[msg.sender] = self._pack_allowance(allowance, month)

    # reverts if user has no lock or duration is too short
    locked: uint256 = 0
    discount: uint256 = 0
    locked, discount = self._preview(_lock, msg.value, _lock != msg.sender)
    assert locked >= _min_locked, "price change"

    veyfi.modify_lock(locked, 0, _lock)
    if _callback != empty(address):
        DiscountCallback(_callback).delegated(_lock, msg.sender, msg.value, locked)

    raw_call(management, b"", value=msg.value)
    log Buy(msg.sender, msg.value, locked, discount, _lock)
    return locked

@external
def withdraw(_token: address, _amount: uint256):
    """
    @notice Withdraw a token from the contract
    @param _token Token to withdraw
    @param _amount Amount to withdraw
    """
    assert msg.sender == management
    assert ERC20(_token).transfer(msg.sender, _amount, default_return_value=True)

@internal
@pure
def _pack_allowance(_allowance: uint256, _month: uint256) -> uint256:
    assert _allowance <= ALLOWANCE_MASK and _month <= MONTH_MASK
    return _allowance | shift(_month, -MONTH_SHIFT)

@internal
@pure
def _unpack_allowance(_packed: uint256) -> (uint256, uint256):
    return _packed & ALLOWANCE_MASK, shift(_packed, MONTH_SHIFT)