// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc.    | 2022
// Bounty Sports - The League | 2022
pragma solidity >=0.8.0 <0.9.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BountySports is ERC721Enumerable, Ownable {
    
    //sale settings
    uint256 public cost = 0.099 ether;
    uint256 public maxSupply = 3333;
    uint256 public maxMint = 10;

    string public baseURI;
    address pagzi = 0xeBaBB8C951F5c3b17b416A3D840C52CcaB728c19;
    address bounty = 0xB3b0B0648F5dEd9736f9b4287fCc4D1A4277a33e;

    //date variables
    uint256 public publicDate = 1648850400;
    uint256 public presaleDate = 1648753200;

    //mint passes/claims
    mapping(address => uint256) public mintPasses;
    address public proxyRegistryAddress;

    constructor() ERC721("Bounty Sports", "BOUNTY") {
    setBaseURI("https://bountysports.nftapi.art/meta/");
    proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

    // external
    function mint(uint256 count) external payable{
    require(count < maxMint + 1, "Too many" );
    require((publicDate <= block.timestamp),"DATE");
    uint256 totalSupply = _owners.length;
    require(totalSupply + count < maxSupply + 1, "Sorry" );
    require(msg.value >= cost * count,"Low ETH");
    for(uint i; i < count; i++) { 
        _mint(_msgSender(), totalSupply + i + 1);
    }
    }
    function mintPresale(uint256 count) external payable{    
    require(count > 0, "Duh!" );
    require((presaleDate <= block.timestamp),"DATE");
    uint256 totalSupply = _owners.length;
    require(totalSupply + count < maxSupply + 1, "Sorry" );
    uint256 reserve = mintPasses[msg.sender];
    require(reserve > 0, "Low reserve");
    require(msg.value >= cost * count, "Low ETH");
    for (uint256 i = 0; i < count; ++i) {
        _mint(_msgSender(), totalSupply + i + 1);
    }
    mintPasses[msg.sender] = reserve - count;
    delete totalSupply;
    delete reserve;
    }
    //only owner
    function gift(uint[] calldata quantity, address[] calldata recipient) public onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );
    uint totalQuantity = 0;
    uint256 totalSupply = _owners.length;
    for(uint i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
    }
    require(totalSupply + totalQuantity + 1 <= maxSupply, "0" );
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
    function setPublicDate(uint256 _publicDate) external onlyOwner {
    publicDate = _publicDate;
    }
    function setEndDate(uint256 _presaleDate) external onlyOwner {
    presaleDate = _presaleDate;
    }
    function setDates(uint256 _publicDate, uint256 _presaleDate) external onlyOwner {
    publicDate = _publicDate;
    presaleDate = _presaleDate;
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
    function isApprovedForAll(address _owner, address operator) public view override(IERC721,ERC721) returns (bool) {
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
        payable(bounty).transfer((balance * 800) / 1000);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}