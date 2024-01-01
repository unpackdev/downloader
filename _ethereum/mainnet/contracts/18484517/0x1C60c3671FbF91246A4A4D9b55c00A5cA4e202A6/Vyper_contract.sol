# @version 0.3.7

from vyper.interfaces import ERC4626

ASSET: constant(address) = 0x24Ae2dA0f361AA4BE46b48EB19C91e02c5e4f27E # mevETH
UNIT: constant(uint256) = 1_000_000_000_000_000_000

@external
@view
def rate(_asset: address) -> uint256:
    assert _asset == ASSET
    return ERC4626(ASSET).convertToAssets(UNIT)