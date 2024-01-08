// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Tradable.sol";

contract Tiger is ERC721Tradable {
    using SafeMath for uint256;

    bool public saleIsActive;
    uint256 public maxByMint;
    uint256 public maxSupply;
    uint256 public maxPublicSupply;
    uint256 public maxReservedSupply;
    uint256 public totalPublicSupply;
    uint256 public totalReservedSupply;
    uint256 public fixedPrice;
    address public daoAddress;
    address public devAddress;
    string internal baseTokenURI;

    mapping(address => uint256) internal whitelist;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        maxByMint = 20;
        maxSupply = 3333;
        maxReservedSupply = 105;
        fixedPrice = 0.04 ether;
        maxPublicSupply = maxSupply - maxReservedSupply;
        daoAddress = 0xe0EB38919fAD2A979B8C946C1c8f032F689b288B;
        devAddress = 0x17AC35d89048714FC3DE2D8249D2a223d3bdaaA4;
        baseTokenURI = 'https://www.tigercubkings.io/api/meta/1/';
        _initWhitelist();
    }

    function contractURI() public pure returns (string memory) {
        return "https://www.tigercubkings.io/api/contract/1";
    }

    function _initWhitelist() private {
        whitelist[0x0EdebA55DCb571fa48603ac3EC78C0fF103B6f2E] = 1;
        whitelist[0x257840407970BAF9150305137aAC44eb18d55cF0] = 1;
        whitelist[0x1a51aF25962d7BfEa60b5481E3c9B2e363ba7E30] = 1;
        whitelist[0x67DD09a32EE4dc97362175f98B5253cd15c8E96A] = 1;
        whitelist[0xeBd6322c2811A93289aCB25bEAA1cb3937147Cdc] = 1;
        whitelist[0xDecade78120A1fadac0903DEeA733192dC6a530E] = 1;
        whitelist[0x9cBd60A51b54aB626cDE7861Afe43D2CD82dA327] = 1;
        whitelist[0xF98c2cf470F703e9C46D9015Bb4B8Df17c41FAF1] = 1;
        whitelist[0x954021052072c6B6d8E1fEb5FA2C093CBA72a344] = 1;
        whitelist[0x8485BA1e0f63a9fF1976FB46Ac91e180D263Eb0A] = 1;
        whitelist[0x3b10f088D7a83E92E91D4A84FE2c656AF92a801D] = 1;
        whitelist[0xAf8E52567099FD3CDdf93670C77c6e860156C070] = 1;
        whitelist[0x95131b9190f129bbe2c268804Bf39c43e3711Ac2] = 1;
        whitelist[0x6d87BB75f27bA731ba0C8b89247E2469E7591993] = 1;
        whitelist[0x5126757159cdf32Ed1018525939E2A90BF4C362E] = 1;
        whitelist[0xC53B74d59DaD5f335a7dB7236d77Eba1236e9a92] = 1;
        whitelist[0xD1ce969775935E18Fac21BE5b06992C380824b91] = 1;
        whitelist[0x25cF121D9e6fD267166B32d32C7BEb7Df74675E3] = 1;
        whitelist[0x1A6B77AdAa1cd581c46dE08F0B325f5F996dA9B3] = 1;
        whitelist[0x4a19DBD4CE30B251E578b9810D954ebE63C3246A] = 1;
        whitelist[0x8047adC649f59B7aD22BF77cec99F17609f52105] = 1;
        whitelist[0x65fBc6cd62b96a612484Db07c279722c6039E4f8] = 1;
        whitelist[0x662a7Ff3942D513a295AF2CbBa351462530559A6] = 1;
        whitelist[0xAF96adaF8E5cf6e9F3A17D4701B056637717F84f] = 1;
        whitelist[0xc3dB4FB5C878015F8bEE801E39D8e949fc241684] = 1;
        whitelist[0x51050ec063d393217B436747617aD1C2285Aeeee] = 1;
        whitelist[0x38bAc6e0c39AcCbB62F2230b66D2CF3956904d39] = 1;
        whitelist[0xFAd3b8806E7958325f13061C2B4B4758617e03B8] = 1;
        whitelist[0x753C9364Ef3060C3428833aA4a85081dbe9a96D9] = 1;
        whitelist[0x1079cA22d0F35a17D63cf3F5920b67Aa63168a59] = 1;
        whitelist[0x4E96895D17c151CD5071634bDD1CE765A8A6D511] = 1;
        whitelist[0x5DDdaFFe861955cF9CE22d0A110608fb7c8876b2] = 1;
        whitelist[0xC8CE0d7337d79D33c78BBdC955db2f18a454CaC8] = 1;
        whitelist[0x40B4911489A87858F7e6765FDD32DFdD9D449aC6] = 1;
        whitelist[0xE2c47b4c62ede80de876AB74E74238835315D982] = 1;
        whitelist[0xA17138c0675173B8Ea506Fb1b96FA754BC316cc2] = 1;
        whitelist[0x64D8392ba13EA89686aF28A9093207A9e1fe15BD] = 1;
        whitelist[0xEC080DbeE8F60c8E6d7c3F52e10832718d2b8D5A] = 1;
        whitelist[0x6E2Ce0D1f8Ab9C82Be2D0beC89a29fD9AF9837c9] = 1;
        whitelist[0x24C3BA6F5b37988542E2f74693feF24aF8755544] = 1;
        whitelist[0xD8Cc8fD1B9F9820aC2CF7b481029110497C96C34] = 1;
        whitelist[0x5ed39Ed5C210bdB9e67385478323E6113C33b1F0] = 1;
        whitelist[0x49379EFAE465C8d420357142477C09386Cc1e764] = 1;
        whitelist[0x56b65992dE3a5E8697308AEC09312DE388c8bD57] = 1;
        whitelist[0x7B6Ad30147A685C37595661976288a99425F766c] = 1;
        whitelist[0x267B03BE841c7C55827fE687DF91449B2A4c7a5c] = 1;
        whitelist[0x791Bf46d6aa1132f809665302b3C1069986Ee0Fe] = 1;
        whitelist[0x3A2ae455C0087756054Cd7A31738EA2F589e5f62] = 1;
        whitelist[0x82f436Ad6Aa3387b33a1fA7c3E0992BDA6548dd0] = 1;
        whitelist[0xE5870d82CBB190a7263DDF7172c2A7157D6C48B9] = 1;
        whitelist[0x1ad0292e17F5d57cAe3b05e31E8703e0562d24A9] = 1;
        whitelist[0xC17aA0E19a9192881c6628a4da8FAE4b88c30859] = 1;
        whitelist[0x0aE63abf7F2200308924Cd3604FdB52bB5925C73] = 1;
        whitelist[0x5688969aD44310d800dd93feec3a7842B5DA16dd] = 1;
        whitelist[0x6D997a16d2A80CC6B20548AdCa807A6342819536] = 1;
        whitelist[0xd60b18C32c49026bc65a2373B531AB18ff8fAa57] = 1;
        whitelist[0x688A46b1A19193011F0F5dC4675878073F640c89] = 1;
        whitelist[0x83068A157eBc50958065bb5492688387eE29cEC9] = 1;
        whitelist[0xE191892b9a3bC60A943EFD572Cf47c7d05A150F3] = 1;
        whitelist[0xcD75B8ef4E07cc786844Fca2Ad1316C4c5B0890c] = 1;
        whitelist[0xDd083b3F91F389F756E517888B9daf89CE08A3c4] = 1;
        whitelist[0x2d05F736cbFef5f1E84b097E09d48575e8995848] = 1;
        whitelist[0x848b3FeFf4F60Ba9a9cF8f92C9A4234D508d2D30] = 1;
        whitelist[0xAfC786F195F4a1C47Eb364f94066e49EcA738998] = 1;
        whitelist[0xfA84ee7E30a6780719876eC5d8a9640f0263979c] = 1;
        whitelist[0x02A82254DC04EFC9b0242c278322BC4acA464522] = 1;
        whitelist[0x9c6FD546D6f81Efbe1aAE0C7a2b5BF4E690BEE98] = 1;
        whitelist[0x40622F008eBe5594A16631522485502cfe06Fa12] = 1;
        whitelist[0xBd7041c03B68467a55596F375c3e4Bb716406a23] = 1;
        whitelist[0x7Cc2c385b541107b9F74D9d830FA3c250bD2eb7E] = 1;
        whitelist[0x734ebeCE6D698a50CF90aC9bF15e3F16dC34a204] = 1;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    function _mintN(uint numberOfTokens) private {
        require(numberOfTokens <= maxByMint, "Max mint exceeded");
        require(totalPublicSupply + numberOfTokens <= maxPublicSupply, "Max supply reached");
        uint startTokenId = this.totalSupply() + 1;
        for(uint i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, startTokenId + i);
            totalPublicSupply++;
        }
    }

    function mintPublic(uint numberOfTokens) external payable { 
        require(saleIsActive, "Sale not active");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(numberOfTokens);
    }

    function mintReserved(address _to, uint numberOfTokens) external onlyOwner {
        require(totalReservedSupply + numberOfTokens <= maxReservedSupply, "Max supply reached");
        uint startTokenId = this.totalSupply() + 1;
        for(uint i = 0; i < numberOfTokens; i++) {
            _mint(_to, startTokenId + i);
            totalReservedSupply++;
        }
    }

    function flipSaleStatus() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        daoAddress = _daoAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setFixedPrice(uint256 _fixedPrice) external onlyOwner {
        fixedPrice = _fixedPrice;
    }

    function setSupply(uint256 _maxSupply, uint256 _maxReservedSupply) external onlyOwner {
        maxSupply = _maxSupply;
        maxReservedSupply = _maxReservedSupply;
        maxPublicSupply = maxSupply - maxReservedSupply;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        _withdraw(devAddress, balance.mul(10).div(100));
        _withdraw(daoAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Tx failed");
    }

    function setWhitelistAllocation(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] =  1;
        }
    }

    function getWhitelistAllocation(address _for) external view returns (uint256) {
        return whitelist[_for];
    }

    function mintWhitelist(uint256 numberOfTokens) external payable {    
        require(whitelist[msg.sender] > 0, "Not eligible to claim");
        require(fixedPrice * numberOfTokens <= msg.value, "Eth val incorrect");
        _mintN(numberOfTokens);
    }

}