interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_to: address) -> uint256: view
    def nDIVIDEND() -> uint256: view

interface IDEFILABSnft:
    def ownerOf(tokenId: uint256) -> address: nonpayable

Deployer: public(address)
DividendAccounting: HashMap[uint256, uint256]
ClaimedTranche: HashMap[address, HashMap[uint256, bool]]
nTranches: public(uint256)
Name: public(String[64])
MetaWhaleXAU: public(address)
PRIA: public(address)
DEFILABS_NFT: public(address)

@external
def __init__(_name: String[64]):
    self.Name = _name
    self.Deployer = msg.sender
    self.MetaWhaleXAU = ZERO_ADDRESS
    self.PRIA = 0xb9871cB10738eADA636432E86FC0Cb920Dc3De24
    self.DEFILABS_NFT = 0xff9315c2c4c0208Edb5152F4c4eBec75e74010c5

@view
@external
def viewTranche(_trancheNumber: uint256) -> uint256:
    return self.DividendAccounting[_trancheNumber]

@external
def setMWcontract(_metawhale: address) -> bool:
    assert msg.sender != ZERO_ADDRESS
    assert msg.sender == self.Deployer
    assert _metawhale != ZERO_ADDRESS
    self.MetaWhaleXAU = _metawhale
    return True

@external
def register(_prevBal: uint256) -> bool:
    currentbal: uint256 = IERC20(self.PRIA).balanceOf(self) - _prevBal
    paycount: uint256 = IERC20(self.MetaWhaleXAU).nDIVIDEND()
    self.nTranches = paycount
    self.DividendAccounting[paycount] = currentbal
    return True

@external
def receiveDividendSingle(_tranche: uint256, tokenId: uint256) -> bool:
    assert tokenId == 0 or tokenId == 362
    nftowner: address = IDEFILABSnft(self.DEFILABS_NFT).ownerOf(tokenId)
    assert self.ClaimedTranche[nftowner][_tranche] == False
    dividendAmount: uint256 = self.DividendAccounting[_tranche]/2
    IERC20(self.PRIA).transfer(nftowner, dividendAmount)
    self.ClaimedTranche[nftowner][_tranche] = True
    return True

@external
def receiveDividendTriple(_tranche1: uint256, _tranche2: uint256, _tranche3: uint256, tokenId: uint256) -> bool:
    assert tokenId == 0 or tokenId == 362
    nftowner: address = IDEFILABSnft(self.DEFILABS_NFT).ownerOf(tokenId)
    assert self.ClaimedTranche[nftowner][_tranche1] == False
    assert self.ClaimedTranche[nftowner][_tranche2] == False
    assert self.ClaimedTranche[nftowner][_tranche3] == False
    dividendAmount: uint256 = (self.DividendAccounting[_tranche1] + self.DividendAccounting[_tranche2] + self.DividendAccounting[_tranche3])/2
    IERC20(self.PRIA).transfer(nftowner, dividendAmount)
    self.ClaimedTranche[nftowner][_tranche1] = True
    self.ClaimedTranche[nftowner][_tranche2] = True
    self.ClaimedTranche[nftowner][_tranche3] = True
    return True