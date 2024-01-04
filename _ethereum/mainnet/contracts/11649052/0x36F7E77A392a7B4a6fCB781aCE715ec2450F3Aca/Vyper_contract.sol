kingasset: address
valueasset: address
chiefmetapod: address
chiefdollyfractal: address
airdropAddress: address
mantisfaucet: address
nft_faucet: address
marketing_faucet: address
dev_faucet: address
defilabs: address
defilabs_community: address
static_vault: address
elastic_vault: address
exchange_vault: address
dex_vault: address
dex_fund: address
addy_ref: HashMap[uint256, address]
blacklist: HashMap[address, bool]
cloner: HashMap[address, bool]
assets: HashMap[String[10], address]
liquidityPools: HashMap[uint256, address]
announcementsCount: public(uint256)
announce: HashMap[uint256, String[500]]

@external
def __init__():
    self.defilabs = msg.sender
    self.defilabs_community = msg.sender
    self.announcementsCount = 0

@external
def setAnnouncement(_message: String[500]) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.announce[self.announcementsCount] = _message
        self.announcementsCount += 1
    return True

@external
def setKingAsset(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.kingasset = _address
    return True

@external
def setValueAsset(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.valueasset = _address
    return True

@external
def setChiefMetapod(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.chiefmetapod = _address
    return True

@external
def setChiefDollyFractal(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.chiefdollyfractal = _address
    return True

@external
def setAirdropAddress(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.airdropAddress = _address
    return True

@external
def setMantisFaucet(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.mantisfaucet = _address
    return True

@external
def setNFTfaucet(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.nft_faucet = _address
    return True

@external
def setMarketingFaucet(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.marketing_faucet = _address
    return True

@external
def setdevFaucet(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.dev_faucet = _address
    return True

@external
def setDEFILABS(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.defilabs = _address
    return True

@external
def setDEFILABScommunity(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.defilabs_community = _address
    return True

@external
def setStaticVault(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.static_vault = _address
    return True

@external
def setElasticVault(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.elastic_vault = _address
    return True

@external
def setExchangeVault(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.exchange_vault = _address
    return True

@external
def setDEXVault(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.dex_vault = _address
    return True

@external
def setDEXfund(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.dex_fund = _address
    return True

@external
def setAddyRef(_tag: uint256, _address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.addy_ref[_tag] = _address
    return True

@external
def ToggleBlacklist(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        if self.blacklist[_address] == True:
            self.blacklist[_address] = False
        else:
            self.blacklist[_address] = True
    return True

@external
def setAssets(_ticker: String[10], _address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        self.assets[_ticker] = _address
    return True

@external
def ToggleCloner(_address: address) -> bool:
    if msg.sender == self.defilabs or msg.sender == self.defilabs_community:
        if self.cloner[_address] == True:
            self.cloner[_address] = False
        else:
            self.cloner[_address] = True
    return True

@view
@external
def DEFILABS() -> address:
    return self.defilabs

@view
@external
def DEFILABS_COMMUNITY() -> address:
    return self.defilabs_community

@view
@external
def Announcements(_number: uint256) -> String[500]:
    return self.announce[_number]

@view
@external
def KingAsset() -> address:
    return self.kingasset

@view
@external
def ValueAsset() -> address:
    return self.valueasset

@view
@external
def ChiefMetaPod() -> address:
    return self.chiefmetapod

@view
@external
def ChiefDollyFractal() -> address:
    return self.chiefdollyfractal

@view
@external
def AirdropAddress() -> address:
    return self.airdropAddress

@view
@external
def NFTFaucet() -> address:
    return self.nft_faucet

@view
@external
def MarketingFaucet() -> address:
    return self.marketing_faucet

@view
@external
def devFaucet() -> address:
    return self.dev_faucet

@view
@external
def MantisFaucet() -> address:
    return self.mantisfaucet

@view
@external
def StaticVault() -> address:
    return self.static_vault

@view
@external
def ElasticVault() -> address:
    return self.elastic_vault

@view
@external
def DEXVault() -> address:
    return self.dex_vault

@view
@external
def DEXFund() -> address:
    return self.dex_fund

@view
@external
def AddyRef(_tag: uint256) -> address:
    return self.addy_ref[_tag]

@view
@external
def Assets(_ticker: String[10]) -> address:
    return self.assets[_ticker]

@view
@external
def Blacklist(_address: address) -> bool:
    return self.blacklist[_address]

@view
@external
def ClonerCheck(_address: address) -> bool:
    return self.cloner[_address]