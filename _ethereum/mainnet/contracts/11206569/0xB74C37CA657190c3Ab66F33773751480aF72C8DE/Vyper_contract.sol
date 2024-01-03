# @version 0.2.7

from vyper.interfaces import ERC20

GUSD: constant(address) = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd
GUSD_DECIMALS: constant(uint256) = 2
USDC: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDC_DECIMALS: constant(uint256) = 6


@external
def swap_gusd_usdc(_amount: uint256):
    """
    @notice Swap an amount of GUSD for an amount of USDC
    @dev must approve this contract for `_amount`
    @param _amount uint256 amount to send/receive
    """
    assert ERC20(GUSD).transferFrom(msg.sender, self, _amount)
    assert ERC20(USDC).transfer(msg.sender, _amount * 10 ** (USDC_DECIMALS - GUSD_DECIMALS))


@external
def swap_usdc_gusd(_amount: uint256):
    """
    @notice Swap an amount of USDC for an amount of GUSD
    @dev must approve this contract for `_amount`
    @param _amount uint256 amount to send/receive
    """
    assert ERC20(USDC).transferFrom(msg.sender, self, _amount)
    assert ERC20(GUSD).transfer(msg.sender, _amount / 10 ** (GUSD_DECIMALS - GUSD_DECIMALS))