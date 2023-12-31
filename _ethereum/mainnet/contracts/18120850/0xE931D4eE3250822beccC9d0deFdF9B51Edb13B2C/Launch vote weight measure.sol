# @version 0.3.7
"""
@title Launch vote weight measure
@author 0xkorin, Yearn Finance
@license GNU AGPLv3
@notice
    Defines voting weight at launch, measured as:
      user's st-yETH weight + user's share of bootstrap st-yETH weight
"""

interface Measure:
    def total_vote_weight() -> uint256: view
    def vote_weight(_account: address) -> uint256: view
implements: Measure

interface Staking:
    def totalSupply() -> uint256: view
    def vote_weight(_account: address) -> uint256: view

interface Bootstrap:
    def deposited() -> uint256: view
    def deposits(_account: address) -> uint256: view

staking: public(immutable(address))
bootstrap: public(immutable(address))

@external
def __init__(_staking: address, _bootstrap: address):
    """
    @notice Constructor
    @param _staking Staking contract
    @param _bootstrap Bootstrap contract
    """
    staking = _staking
    bootstrap = _bootstrap

@external
@view
def total_vote_weight() -> uint256:
    """
    @notice Get total vote weight
    @return Total vote weight
    @dev
        Equal to sum of all vote weights at T=inf.
        Care should be taken to use for quorum purposes, as the sum of actual available 
        vote weights will be lower than this due to asymptotical vote weight increase.
    """
    return Staking(staking).totalSupply()

@external
@view
def vote_weight(_account: address) -> uint256:
    """
    @notice Get account vote weight
    @param _account Account to get vote weight for
    @return Account vote weight
    """
    weight: uint256 = Bootstrap(bootstrap).deposits(_account)
    if weight > 0:
        deposited: uint256 = Bootstrap(bootstrap).deposited()
        if deposited > 0:
            weight = weight * Staking(staking).vote_weight(bootstrap) / deposited
        else:
            weight = 0
    return weight + Staking(staking).vote_weight(_account)