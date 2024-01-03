# @version 0.2.7
from vyper.interfaces import ERC20

interface Vault:
    def withdraw(amount: uint256): nonpayable
    def token() -> (address): view


interface Curve:
    def remove_liquidity_one_coin(_token_amount: uint256, i: int128, min_uamount: uint256): nonpayable


@external
def zap_out(vault: address, swap: address, coin: int128):
    token: address = Vault(vault).token()
    Vault(vault).withdraw(ERC20(vault).balanceOf(self))
    withdraw: uint256 = ERC20(token).balanceOf(self)
    ERC20(token).approve(swap, withdraw)
    Curve(swap).remove_liquidity_one_coin(withdraw, coin, 0)