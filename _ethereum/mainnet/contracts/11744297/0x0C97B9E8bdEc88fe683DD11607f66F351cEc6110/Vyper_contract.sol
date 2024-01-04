# @version 0.2.8
from vyper.interfaces import ERC20

interface YFI:
    def mint(account: address, amount: uint256): nonpayable
    def addMinter(minter: address): nonpayable
    def removeMinter(minter: address): nonpayable
    def setGovernance(governance: address): nonpayable


# One-off mint of 6666 YFI
total: constant(uint256) = 6666 * 10 ** 18
treasury: constant(address) = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52
timelock: constant(address) = 0x026D4b8d693f6C446782c2C61ee357Ec561DFB61

yfi: public(YFI)
minted: public(bool)


@external
def __init__():
    self.yfi = YFI(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e)


@external
def brrr():
    assert not self.minted  # dev: already minted
    self.yfi.addMinter(self)
    self.yfi.mint(treasury, total)
    self.yfi.removeMinter(self)
    self.yfi.setGovernance(timelock)
    self.minted = True


@external
def revoke():
    assert self.minted  # dev: not minted
    self.yfi.setGovernance(timelock)