// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2022
// DeadTownZeds | 2022
pragma solidity >=0.8.0 <0.9.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract DeadTownZeds is ERC721Enumerable, Ownable {
    string public baseURI;
    uint256 public cost = 0.042 ether;
    address pagzi = 0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c;
    address macroverse = 0x02F91c73C0B3D50C79821f2F205Cd5268f0D7E57;
    address steven = 0x275715709500a38a86fA48D280Ed88D201681601;

    //date settings
    uint256 public publicDate = 1644426000;
    uint256 public endDate = 1644512400;

    //mint passes/claims
    mapping(address => uint256) public mintPasses;
    address public proxyRegistryAddress;

    constructor(
    string memory _initBaseURI, 
    address _proxyRegistryAddress
    ) ERC721("DeadTownZeds", "ZEDS") {
    setBaseURI(_initBaseURI);
    proxyRegistryAddress = _proxyRegistryAddress;
    initMintPasses();
    }

    // external
    function mint(uint256 count) external payable{
    require((publicDate <= block.timestamp) && (endDate >= block.timestamp),"DATE");
    require(msg.value >= cost * count,"LOW");
    uint256 totalSupply = _owners.length;
    for(uint i; i < count; i++) { 
    _mint(_msgSender(), totalSupply + i + 1);
    }
    }
    function claim() external{
    uint256 totalSupply = _owners.length;
    require((publicDate <= block.timestamp) && (endDate >= block.timestamp));
    uint256 reserve = mintPasses[msg.sender];
    require(reserve > 0, "Low reserve");
    _mint(_msgSender(), totalSupply + 1);
    mintPasses[msg.sender] = reserve - 1;
    delete reserve;
    }
    //only owner
    function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    uint256 totalSupply = _owners.length;
    for(uint i; i < recipient.length; ++i){
    for(uint j; j < quantity[i]; ++j){
    _mint(recipient[i], totalSupply + j + 1);
    }
    }
    }
    function setCost(uint256 _cost) external onlyOwner {
    cost = _cost;
    }
    function setPublicDate(uint256 _publicDate) external onlyOwner {
    publicDate = _publicDate;
    }
    function setEndDate(uint256 _endDate) external onlyOwner {
    endDate = _endDate;
    }
    function setDates(uint256 _publicDate, uint256 _endDate) external onlyOwner {
    publicDate = _publicDate;
    endDate = _endDate;
    }
    function setMintPass(address _address,uint256 _quantity) external onlyOwner {
    mintPasses[_address] = _quantity;
    }
    function setMintPasses(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
    for(uint256 i; i < _addresses.length; i++){
    mintPasses[_addresses[i]] = _amounts[i];
    }
    }
    //internal
    function initMintPasses() internal {
    mintPasses[0x275715709500a38a86fA48D280Ed88D201681601] = 10;
    mintPasses[0xE2542857B06Ae5cdf7c4664f417e7a56312Da84E] = 5;
    mintPasses[0x68fFfD5e532f8ED2727ACFEd097Ee1D065030b9c] = 5;
    mintPasses[0x6fa1D14fB34C002c30419BbBFfD725e0A70B43Aa] = 5;
    mintPasses[0xF4617b57ad853f4Bc2Ce3f06C0D74958c240633c] = 10;
    mintPasses[0x8894802E3599EAA22e729a2DfFAab09c055eE84c] = 100;

    mintPasses[0xF1ff23e094C3f83C39d1F5deb92A3e72Ca501cFc] = 5;
    mintPasses[0x8500C52ca27f326D3a64B792aA215B1166503076] = 5;
	
	//winners
    mintPasses[0x2ad6623Ca66DC36610270fDd7327D904Be6305d7] = 1;
    mintPasses[0x815CD9963ed67Fc9a11b18C3f7523885dF2869F7] = 1;
    mintPasses[0x664D7462634fAC1815353A10f138750Ee11a91F6] = 1;
    mintPasses[0x04aFa47203132436Cd4aAFA10547304B25F7006B] = 1;
    mintPasses[0xa2116eB15F9DA56190d5Ac7f500101558b707968] = 1;
    mintPasses[0x2a5a847DFeF231ED9a680d32C3Bb39582423E72F] = 1;
    mintPasses[0x79c6174F46bD6a90f8d775887F90fBe7ba8A2ae3] = 1;
	
	//twitter contest
    mintPasses[0xB2E0f2fb1313FCD8870D683A812a35a483e4E843] = 1;
    mintPasses[0xD1570F6B6B37Ad73494A1a7199A2922b1C32b914] = 1;
    mintPasses[0x09129Fe9c5D4074B747814b8eCF6D1f43CC39AaC] = 1;
    mintPasses[0xfd86Fb68cbC6759Ed4cDd806303e756c53A93887] = 1;
    mintPasses[0xe16C26D3435DCCe67752fb5fEB0749F5e184d057] = 1;
    mintPasses[0xC6c8347F41916F09B5fa0553100762Dd148e79f8] = 1;
    mintPasses[0x67A50fF70d234D89B59Ed3DCBfAd65c4b96e1fa1] = 1;
    mintPasses[0x9Bc67600E69d5d2Ab62006ca878D95A894492005] = 1;
    mintPasses[0x71Fd9c2440D593AEb4d3C01322F3bcEE32E0712c] = 1;
    mintPasses[0x32B4Cc9c6ef7Ea5A3694403704c12AFc46786C03] = 1;
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }
    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }
        return true;
    }
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator) return true;
        return super.isApprovedForAll(_owner, operator);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(pagzi).transfer((balance * 200) / 1000);
        payable(macroverse).transfer((balance * 750) / 1000);
        payable(steven).transfer((balance * 50) / 1000);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}