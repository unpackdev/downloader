# @version 0.3.1
"""
@title Curve Binance Bridge Wrapper
"""
from vyper.interfaces import ERC20


interface Bridge:
    def bridge(_amount: uint256, _receiver: address, _refund: address): payable
    def quote() -> uint256: view


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
BRIDGE: constant(address) = 0xd4b19642701964c402DFa668F96F294266bC0a86


@external
def __init__():
    assert ERC20(CRV20).approve(BRIDGE, MAX_UINT256)


@payable
@external
def bridge(_token: address, _to: address, _amount: uint256):
    """
    @notice Bridge a token to Polygon mainnet
    @param _token The token to bridge
    @param _to The address to deposit the token to on polygon
    @param _amount The amount of the token to bridge
    """
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    Bridge(BRIDGE).bridge(_amount, _to, msg.sender, value=msg.value)


@pure
@external
def cost() -> uint256:
    """
    @notice Cost in ETH to bridge
    """
    return Bridge(BRIDGE).quote()


@pure
@external
def check(_account: address) -> bool:
    """
    @notice Check if `_account` is allowed to bridge
    @param _account The account to check
    """
    return True