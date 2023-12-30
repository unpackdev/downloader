# @version ^0.2.5

owner: public(address)

interface Uniswap:
    def swapExactETHForTokens(amountOutMin: uint256, path: address[2], to: address, deadline: uint256) -> uint256: payable

uniswap: Uniswap


@external
def __init__(_uniswap: address):
    self.owner = msg.sender
    self.uniswap = Uniswap(_uniswap)


@payable
@external
def swapExactETHForTokens(_min_return: uint256, path: address[2]):
    self.uniswap.swapExactETHForTokens(_min_return, path, msg.sender, block.timestamp + 1800, value=msg.value)