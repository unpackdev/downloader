# @version 0.3.7
"""
@title yETH stake zap
@author 0xkorin, Yearn Finance
@license GNU AGPLv3
"""

from vyper.interfaces import ERC20
from vyper.interfaces import ERC4626

interface Pool:
    def num_assets() -> uint256: view
    def assets(_i: uint256) -> address: view
    def add_liquidity(_amounts: DynArray[uint256, 32], _min_lp_amount: uint256, _receiver: address) -> uint256: nonpayable

token: public(immutable(address))
pool: public(immutable(address))
staking: public(immutable(address))

management: public(address)
pending_management: public(address)

event PendingManagement:
    management: indexed(address)

event SetManagement:
    management: indexed(address)

@external
def __init__(_token: address, _pool: address, _staking: address):
    """
    @notice Constructor
    @param _token Token contract address
    @param _pool Pool contract address
    @param _staking Staking contract address
    """
    token = _token
    pool = _pool
    staking = _staking
    self.management = msg.sender

    assert ERC20(token).approve(staking, max_value(uint256), default_return_value=True)

@external
def approve(_i: uint256):
    """
    @notice Approve transfer of a pool asset to the pool
    @param _i Index of the pool asset to approve
    """
    asset: address = Pool(pool).assets(_i)
    assert ERC20(asset).approve(pool, max_value(uint256), default_return_value=True)

@external
def add_liquidity(
    _amounts: DynArray[uint256, 32], 
    _min_lp_amount: uint256, 
    _receiver: address = msg.sender
) -> (uint256, uint256):
    """
    @notice Deposit assets into the pool and stake
    @param _amounts Array of amount for each asset to take from caller
    @param _min_lp_amount Minimum amount of LP tokens to mint
    @param _receiver Account to receive the LP tokens
    @return Tuple with the amount of LP tokens minted and the amount of staking shares minted
    """
    num_assets: uint256 = Pool(pool).num_assets()
    for i in range(32):
        if i == num_assets:
            break
        amount: uint256 = _amounts[i]
        if amount == 0:
            continue
        asset: address = Pool(pool).assets(i)
        assert ERC20(asset).transferFrom(msg.sender, self, amount, default_return_value=True)

    lp_amount: uint256 = Pool(pool).add_liquidity(_amounts, _min_lp_amount, self)
    shares: uint256 = ERC4626(staking).deposit(lp_amount, _receiver)
    return lp_amount, shares

@external
def rescue(_token: address, _receiver: address):
    """
    @notice Rescue tokens from this contract
    @param _token The token to be rescued
    @param _receiver Receiver of rescued tokens
    """
    assert msg.sender == self.management
    amount: uint256 = ERC20(_token).balanceOf(self)
    assert ERC20(_token).transfer(_receiver, amount, default_return_value=True)

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