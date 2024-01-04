interface IERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_to: address) -> uint256: view
    def nDIVIDEND() -> uint256: view
    def nftDividend(_tranche: uint256) -> uint256: view
    def AirdropAddress() -> address: view
    def KingAsset() -> address: view
    def ValueAsset() -> address: view

interface IDEFILABSnft:
    def ownerOf(tokenId: uint256) -> address: view
    def arAsset_coef1(tokenId: uint256) -> uint256: view

Deployer: public(address)
ClaimedTranche: public(HashMap[address, HashMap[address, HashMap[uint256, bool]]])
nTranches: public(uint256)
Name: public(String[64])
DEFILABS_NFT: public(address)
dustCleanup: public(uint256)
Polaris: public(address)

@external
def __init__(_name: String[64]):
    self.Name = _name
    self.Deployer = msg.sender
    self.Polaris = 0x36F7E77A392a7B4a6fCB781aCE715ec2450F3Aca
    self.DEFILABS_NFT = 0xff9315c2c4c0208Edb5152F4c4eBec75e74010c5
    self.dustCleanup = 50

@view
@external
def TotalDividends(_contract: address) -> uint256:
    return IERC20(_contract).nDIVIDEND()

@view
@external
def viewTranche(_contract: address, _trancheNumber: uint256) -> uint256:
    return IERC20(_contract).nftDividend(_trancheNumber)

@internal
def _pctCalc_minusScale(_value: uint256, _pct: uint256) -> uint256:
    res: uint256 = (_value * _pct) / 10**18
    return res

@internal
def _pctCalc_pctofwhole(_portion: uint256, _ofWhole: uint256) -> uint256:
    res: uint256 = (_portion*10**18)/_ofWhole
    return res

@external
def receiveDividendSingle(_contract: address, _tranche: uint256, tokenId: uint256) -> bool:
    assert tokenId >= 1 and tokenId <= 361
    assert IERC20(_contract).nDIVIDEND() >= _tranche
    nftowner: address = IDEFILABSnft(self.DEFILABS_NFT).ownerOf(tokenId)
    assert nftowner != ZERO_ADDRESS
    assert self.ClaimedTranche[_contract][nftowner][_tranche] == False
    trancheAmount: uint256 = IERC20(_contract).nftDividend(_tranche)
    nftcoef1: uint256 = IDEFILABSnft(self.DEFILABS_NFT).arAsset_coef1(tokenId)
    cut: uint256 = self._pctCalc_pctofwhole(nftcoef1, trancheAmount)
    dividendAmount: uint256 = self._pctCalc_minusScale(trancheAmount, cut)
    IERC20(IERC20(self.Polaris).KingAsset()).transfer(nftowner, dividendAmount)
    self.ClaimedTranche[_contract][nftowner][_tranche] = True
    return True

@external
def receiveDividendTriple(_contract: address, _tranche1: uint256, _tranche2: uint256, _tranche3: uint256, tokenId: uint256) -> bool:
    assert tokenId >= 1 and tokenId <= 361
    assert IERC20(_contract).nDIVIDEND() >= _tranche1
    assert IERC20(_contract).nDIVIDEND() >= _tranche2
    assert IERC20(_contract).nDIVIDEND() >= _tranche3
    nftowner: address = IDEFILABSnft(self.DEFILABS_NFT).ownerOf(tokenId)
    assert nftowner != ZERO_ADDRESS
    assert self.ClaimedTranche[_contract][nftowner][_tranche1] == False
    assert self.ClaimedTranche[_contract][nftowner][_tranche2] == False
    assert self.ClaimedTranche[_contract][nftowner][_tranche3] == False
    tranche1Amount: uint256 = IERC20(_contract).nftDividend(_tranche1)
    tranche2Amount: uint256 = IERC20(_contract).nftDividend(_tranche2)
    tranche3Amount: uint256 = IERC20(_contract).nftDividend(_tranche3)
    nftcoef1: uint256 = IDEFILABSnft(self.DEFILABS_NFT).arAsset_coef1(tokenId)
    cut1: uint256 = self._pctCalc_pctofwhole(nftcoef1, tranche1Amount)
    dividend1Amount: uint256 = self._pctCalc_minusScale(tranche1Amount, cut1)
    cut2: uint256 = self._pctCalc_pctofwhole(nftcoef1, tranche2Amount)
    dividend2Amount: uint256 = self._pctCalc_minusScale(tranche2Amount, cut2)
    cut3: uint256 = self._pctCalc_pctofwhole(nftcoef1, tranche3Amount)
    dividend3Amount: uint256 = self._pctCalc_minusScale(tranche3Amount, cut3)
    IERC20(IERC20(self.Polaris).KingAsset()).transfer(nftowner, dividend1Amount+dividend2Amount+dividend3Amount)
    self.ClaimedTranche[_contract][nftowner][_tranche1] = True
    self.ClaimedTranche[_contract][nftowner][_tranche2] = True
    self.ClaimedTranche[_contract][nftowner][_tranche3] = True
    return True

@external
def receiveMultipleDividend(_contract: address, _tranches: uint256[10], tokenId: uint256) -> bool:
    assert tokenId >= 1 and tokenId <= 361
    for x in _tranches:
        assert IERC20(_contract).nDIVIDEND() >= x
    nftowner: address = IDEFILABSnft(self.DEFILABS_NFT).ownerOf(tokenId)
    assert nftowner != ZERO_ADDRESS
    for x in _tranches:
        assert self.ClaimedTranche[_contract][nftowner][x] == False
    dividendAmount: uint256 = 0
    nftcoef1: uint256 = IDEFILABSnft(self.DEFILABS_NFT).arAsset_coef1(tokenId)
    for x in _tranches:
        trancheamount: uint256 = IERC20(_contract).nftDividend(x)
        cut: uint256 = self._pctCalc_pctofwhole(nftcoef1, trancheamount)
        dividendAmount += self._pctCalc_minusScale(trancheamount, cut)
    IERC20(IERC20(self.Polaris).KingAsset()).transfer(nftowner, dividendAmount)
    for x in _tranches:
        self.ClaimedTranche[_contract][nftowner][x] = True
    return True

@external
def mainetenanceDustSweep() -> bool:
    assert IERC20(IERC20(self.Polaris).ValueAsset()).nDIVIDEND() > self.dustCleanup
    bal: uint256 = IERC20(IERC20(self.Polaris).KingAsset()).balanceOf(self)
    airdropAddy: address = IERC20(self.Polaris).AirdropAddress()
    IERC20(IERC20(self.Polaris).KingAsset()).transfer(airdropAddy, bal)
    self.dustCleanup += 50
    return True