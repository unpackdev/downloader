// contracts/OGCC.sol
// SPDX-License-Identifier: MIT

//   _________   _____  .____       _________   _____    ________    _____    _______    ________ 
//  /   _____/  /  _  \ |    |     /   _____/  /  _  \  /  _____/   /  _  \   \      \  /  _____/ 
//  \_____  \  /  /_\  \|    |     \_____  \  /  /_\  \/   \  ___  /  /_\  \  /   |   \/   \  ___ 
//  /        \/    |    \    |___  /        \/    |    \    \_\  \/    |    \/    |    \    \_\  \
// /_______  /\____|__  /_______ \/_______  /\____|__  /\______  /\____|__  /\____|__  /\______  /
//         \/         \/        \/        \/         \/        \/         \/         \/        \/ 

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";

contract OriginalCoco is ERC721Enumerable, Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private ALCOUNTER;

    bool public ALOpen;
    bool public allowlistsale;
    bool public publicsale;
    bool public supplyliquid = true;

    uint256 public constant RESERVES = 200;
    uint256 public MAX_AL = 5001;
    uint256 public MAX_SUPPLY = 10001;

    uint256 public priceAL = 0.08 ether;
    uint256 public pricePublic = 0.12 ether;

    string  public baseURI;
    string public metadataHash = "";
    address public proxyRegistryAddress;
    mapping(address => bool) public allowList;

    address JO = 0xC9dFf2A236Fd751cC90441C0C8D7aBA07Fe1bfA0;
    address DO = 0x5C565a13f7282AdE6c8210e3baEc08e43D017074;
    address SO = 0x82b6643Ce8Cd0Ab6664C44215039A3fe4c1660e5;
    address SALSATANK = 0xfEb4C0B103d6e6A678A24aD479359B0ca49b8244;
    address RESERVE = 0xcd04B0536502Dc0c9eBa9E7e80f3C715f33AC446;

    constructor(string memory _baseURI, address _proxyRegistryAddress)
    
    ERC721("Original Coco","COCO"){
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function setAllowList(address[] calldata _addresses) external onlyOwner {
        require(ALOpen,                                                         "Allow List Claiming is Paused");
        require(_addresses.length + ALCOUNTER.current() < MAX_AL,               "Not enough AL spots left");

        for (uint256 i = 0; i < _addresses.length; i++) {
            allowList[_addresses[i]] = true;
        }
    }

    function claimAllowList(address _ALister) external payable {
        require(ALOpen,                                                         "Allow List Claiming is Paused");
        require(!allowList[_ALister],                                           "You're Already on the AL");
        require(ALCOUNTER.current() + 1 < MAX_AL,                               "No more AL spots left");
        require(_msgSender()==tx.origin,                                        "No Contracts allowed");
        
        allowList[_ALister] = true;
        ALCOUNTER.increment();
    }

    function reserve() external onlyOwner {
        require(_owners.length == 0,                                            "Reserves already taken.");
        for(uint256 i; i < RESERVES; i++)
            _mint(_msgSender(), i);
    }

    function mintAllowList(uint256 _numcocos) external payable {
        uint256 supply = _owners.length;
        require(allowlistsale,                                              "Allow list sale not active");
        require(allowList[_msgSender()],                                    "You're not on the Allow List or already claimed!");
        require(_numcocos < 3,                                              "A max of 2 Cocos per wallet");
        require(supply + _numcocos < MAX_SUPPLY,                            "Not enough cocos left");
        require(_numcocos * priceAL == msg.value,                           "Invalid funds provided");
        require(_msgSender()==tx.origin,                                    "No Contracts allowed");
    
        allowList[_msgSender()] = false;

        for(uint i; i < _numcocos; i++) { 
            _mint(_msgSender(), supply + i);
        }

    }

    function mintPublic(uint256 _numcocos) external payable {
        uint256 supply = _owners.length;
        require(publicsale,                                                  "Public sale hasn't started");
        require(supply + _numcocos < MAX_SUPPLY,                             "Not enough cocos left");
        require(_numcocos * pricePublic == msg.value,                        "Invalid funds provided");
        require(_msgSender()==tx.origin,                                     "No Contracts allowed");
    
        for(uint i; i < _numcocos; i++) { 
            _mint(_msgSender(), supply + i);
        }
    }

    function withdrawAll() external payable onlyOwner {
        uint256 res = (address(this).balance * 5000) / 100000;
        uint256 dev = (address(this).balance * 13750) / 100000;
        uint256 team = (address(this).balance * 15625) / 100000;
        uint256 salsa = (address(this).balance * 50000) / 100000;
        
        require(payable(JO).send(team));
        require(payable(DO).send(team));
        require(payable(SO).send(dev));
        require(payable(SALSATANK).send(salsa));
        require(payable(RESERVE).send(res));
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) return true;
        return super.isApprovedForAll(_owner, _operator);
    }

    function _mint(address _to, uint256 _tokenId) internal virtual override {
        _owners.push(_to);
        emit Transfer(address(0), _to, _tokenId);
    }

    function setSupply(uint256 _newSupply) external onlyOwner() {
        require(supplyliquid,           "Supply is already frozen");
        MAX_SUPPLY = _newSupply;
    }

    function setALMax(uint256 _newALMax) external onlyOwner(){
        require(supplyliquid,           "Supply is already frozen");
        MAX_AL = _newALMax;
    }

    function freezeSupply() external onlyOwner{
        supplyliquid = false;
    }

    function toggleALOpen() external onlyOwner {
        ALOpen = !ALOpen;
    }

    function toggleAllowListSale() external onlyOwner {
        allowlistsale = !allowlistsale;
    }
  
    function togglePublicSale() external onlyOwner {
        publicsale = !publicsale;
    }

    function setPublicPrice(uint256 _newPrice) external onlyOwner() {
        pricePublic = _newPrice;
    }
    function setALPrice(uint256 _newPrice) external onlyOwner() {
        priceAL = _newPrice;
    }

    function getALCount() external view returns(uint256){
        return ALCOUNTER.current();
    }

    function setMetadataHash(string memory _hash) external onlyOwner {
        metadataHash = _hash;
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}