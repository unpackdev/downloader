// SPDX-License-Identifier: MIT
// Author: Pagzi Tech Inc. | 2022
// Apes of Galata - AoG | 23/04/1920 - ∞
pragma solidity >=0.8.0 <0.9.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract ApesOfGalata is ERC721Enumerable, Ownable {

    //sale settings
    uint256 public cost = 0.066 ether;
    uint256 public costPre = 0.044 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxSupplyPre = 2000;
    uint256 public maxMint = 10;
    uint256 public maxMintPre = 2;
    uint256 public maxMintOG = 4;

    //backend settings
    string public baseURI;
    address internal immutable pagzidev = 0xeBaBB8C951F5c3b17b416A3D840C52CcaB728c19;
    address internal immutable founder = 0x798c55F940dcF5E76a8767FeD389507aDAB6424d;
    address internal immutable partner1 = 0x3F468Aeb495bA39Cc9af5b02150d5740f2aC54E6;
    address internal immutable partner2 = 0x16b3257332de4B09f2638a7cCC46FC49F5E19b6D;
    address internal immutable partner3 = 0x150396a3153d522ACBE5b03d9eF73A40F94020D5;
    address internal immutable partner4 = 0x882Ec39B5c19A71B5D95515fd911fDB06A667c40;
    address internal proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    mapping(address => bool) public projectProxy;

    //date variables
    uint256 public publicDate = 1650751200;
    uint256 public preDate = 1650740400;

    //mint passes
    mapping(address => uint256) public mintPasses;

    //royalty settings
    address public royaltyAddr = 0x546f3882DD1f90A4D399f843DB23EB473a88CAEd;
    uint256 public royaltyFee = 7500;

    function getPrice(uint256 quantity) public view returns (uint256){
    uint256 totalPrice = 0;
    if (publicDate < block.timestamp) {
    for (uint256 i = 0; i < quantity; i++) {
    totalPrice += cost;
    }
    return totalPrice;
    }
    uint256 current = _owners.length;
    for (uint256 j = 0; j < quantity; j++) {
    if (current > maxSupplyPre + 1) {
    totalPrice += cost;
    } else {
    totalPrice += costPre;
    }
    current++;
    }
    delete current;
    return totalPrice;
    }

    modifier checkLimit(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount - 1 < maxMint, "Invalid mint amount!");
        require(_owners.length + _mintAmount < maxSupply + 1, "Max supply exceeded!");
        _;
    }
    modifier checkLimitPre(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount - 1 < maxMintPre, "Invalid mint amount!");
        require(_owners.length + _mintAmount < maxSupply + 1, "Max supply exceeded!");
        _;
    }
    modifier checkLimitOG(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount - 1 < maxMintOG, "Invalid mint amount!");
        require(_owners.length + _mintAmount < maxSupply + 1, "Max supply exceeded!");
        _;
    }
    modifier checkDate() {
        require((publicDate <= block.timestamp),"Public sale is not yet!");
        _;
    }
    modifier checkPreDate() {
        require((preDate <= block.timestamp),"Presale is not yet!");
        _;
    }
    modifier checkPrice(uint256 _mintAmount) {
        require(msg.value >= getPrice(_mintAmount), "Insufficient funds!");
        _;
    }

    constructor() ERC721("Apes of Galata", "AoG") {
        baseURI = "https://theapesofgalata.nftapi.art/meta/";
    }

    // external
    function mint(uint256 count) external payable checkLimit(count) checkPrice(count) checkDate {
        uint256 totalSupply = _owners.length;
        for(uint i; i < count; i++) { 
            _mint(msg.sender, totalSupply + i + 1);
        }
    }
    function mintOG(uint256 count) external payable checkLimitOG(count) checkPrice(count) checkPreDate {
        uint256 totalSupply = _owners.length;
        uint256 reserve = mintPasses[msg.sender];
        require((reserve - count + 1) > 0, "Low reserve!");
        for (uint256 i = 0; i < count; ++i) {
            _mint(msg.sender, totalSupply + i + 1);
        }
        mintPasses[msg.sender] = reserve - count;
        delete totalSupply;
        delete reserve;
    }
    function mintPre(uint256 count) external payable checkLimitPre(count) checkPrice(count) checkPreDate {
        uint256 reserve = balanceOf(msg.sender);
        require((reserve + count ) < 3, "Low reserve!");
        uint256 totalSupply = _owners.length;
        for (uint256 i = 0; i < count; ++i) {
            _mint(msg.sender, totalSupply + i + 1);
        }
        delete totalSupply;
        delete reserve;
    }

    //only owner
    function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    uint totalQuantity;
    uint256 totalSupply = _owners.length;
    for(uint i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
    }
    require(totalSupply + totalQuantity + 1 <= maxSupply, "Not enough supply!" );
        for(uint i = 0; i < recipient.length; ++i){
        for(uint j = 0; j < quantity[i]; ++j){
            _mint(recipient[i], totalSupply + 1);
            totalSupply++;
        }
        }
    }
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }
    function setCostPre(uint256 _costPre) external onlyOwner {
        costPre = _costPre;
    }
    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    function setSupplyPre(uint256 _maxSupplyPre) external onlyOwner {
        maxSupplyPre = _maxSupplyPre;
    }
    function setPublicDate(uint256 _publicDate) external onlyOwner {
        publicDate = _publicDate;
    }
    function setPreDate(uint256 _preDate) external onlyOwner {
        preDate = _preDate;
    }
    function setDates(uint256 _publicDate, uint256 _preDate) external onlyOwner {
        publicDate = _publicDate;
        preDate = _preDate;
    }
    function setMintPass(address _address,uint256 _quantity) external onlyOwner {
        mintPasses[_address] = _quantity;
    }
    function setMintPasses(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        for(uint256 i; i < _addresses.length; i++){
        mintPasses[_addresses[i]] = _amounts[i];
        }
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function switchProxy(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }
    function setProxy(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }
    //ERC-2981 Royalty Implementation
    function setRoyalty(address _royaltyAddr, uint256 _royaltyFee) public onlyOwner {
        require(_royaltyFee < 10001, "ERC-2981: Royalty too high");
        royaltyAddr = _royaltyAddr;
        royaltyFee = _royaltyFee;
    }
    function royaltyInfo(uint256, uint256 value) external view 
    returns (address receiver, uint256 royaltyAmount){
    require(royaltyFee > 0, "ERC-2981: Royalty too high");
    return (royaltyAddr, (value * royaltyFee) / 10000);
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
        uint16 j = 0;
        for( uint i; i < _owners.length; i++ ){
          if(_owner == _owners[i]){
            tokensId[j] = i + 1; 
            j++;
            }
            if(j == tokenCount) return tokensId;
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
    function isApprovedForAll(address _owner, address operator) public view override(IERC721,ERC721) returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(pagzidev).transfer((balance * 250) / 1000);
        payable(founder).transfer((balance * 235) / 1000);
        payable(partner1).transfer((balance * 250) / 1000);
        payable(partner2).transfer((balance * 100) / 1000);
        payable(partner3).transfer((balance * 150) / 1000);
        payable(partner4).transfer((balance * 15) / 1000);
    }
}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}