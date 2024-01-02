# @version 0.3.7

interface RocketPoolBalances:
    def getTotalRETHSupply() -> uint256: view
    def getTotalETHBalance() -> uint256: view

interface RocketPoolStorage():
    def getAddress(_key: bytes32) -> address: view

ASSET: constant(address) = 0xae78736Cd615f374D3085123A210448E74Fc6393 # rETH
STORAGE: constant(address) = 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46
BALANCES: constant(address) = 0x07FCaBCbe4ff0d80c2b1eb42855C0131b6cba2F4
UNIT: constant(uint256) = 1_000_000_000_000_000_000

@external
@view
def rate(_asset: address) -> uint256:
    assert _asset == ASSET
    return RocketPoolBalances(BALANCES).getTotalETHBalance() * UNIT / RocketPoolBalances(BALANCES).getTotalRETHSupply()

# for testing purposes
@external
@view
def verify_balances_contract() -> bool:
    balances: address = RocketPoolStorage(STORAGE).getAddress(keccak256('contract.addressrocketNetworkBalances'))
    return balances == BALANCES