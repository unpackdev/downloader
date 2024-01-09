// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./BitMaps.sol";
import "./console.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract MoPAr is Initializable, OwnableUpgradeable, AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable {
    using BitMaps for BitMaps.BitMap;

    struct Collection {
        string name;
        string artist;
        uint128 circulating;
        uint128 max;
        uint256 price;
    }

    struct Entry {
        bytes32 signature;
        uint256 price;
        string name;
        string description;
        string image;
        string[20] attributes;
    }

    event CollectionCreated(uint256 collectionId);

    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 private constant SEPARATOR = 10**4;

    mapping(address => uint256) public whitelist;
    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => Entry) private _theCatalogue;

    BitMaps.BitMap private _isCollectionUnpaused;
    bool public isMuseumOpen;

    uint256 private _nextCollectionId;

    address public metadataAddress;

    function initialize(bool isMuseumOpen_, address adminAddress_) public initializer {
        __ERC721_init("Museum Of Permuted Art", "MOPAR");
        __Ownable_init();

        _nextCollectionId = 1;
        isMuseumOpen = isMuseumOpen_;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress_);
    }

    // catalogueEntry { name, description, image, attributes* }
    function claimArt(uint256 tokenId, string[] calldata catalogueEntry) external payable {
        require(isMuseumOpen == true, "MUSEUM_CLOSED");
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        require(_isCollectionUnpaused.get(_getCollectionId(tokenId)), "COLLECTION_IS_PAUSED");
        
        require(_getPrice(tokenId) <= msg.value, "INSUFFICIENT_ETH");

        _mint(tokenId, catalogueEntry);
    }

    function whitelistClaim(uint256 tokenId, string[] calldata catalogueEntry) external payable {
        require(isMuseumOpen == true, "MUSEUM_CLOSED");
        require(whitelist[msg.sender] == 888 || tokenId == whitelist[msg.sender], "INVALID_WHITELIST"); //888 is wildcard for any token
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
    
        require(_getPrice(tokenId) <= msg.value, "INSUFFICIENT_ETH");

        _mint(tokenId, catalogueEntry);
        whitelist[msg.sender] = 0;
    }

    function daoClaim(uint256 tokenId, string[] calldata catalogueEntry) external onlyRole(MANAGER_ROLE) {
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        
        _mint(tokenId, catalogueEntry);
    }

    function getPrice(uint256 tokenId) external view returns (uint256) {
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        
        return _getPrice(tokenId);
    }


    function _getPrice(uint256 tokenId) internal view returns (uint256) {
        if (_theCatalogue[tokenId].price != 0)
            return _theCatalogue[tokenId].price;
        else
            return _collections[_getCollectionId(tokenId)].price;
    }

    function _mint(uint256 tokenId, string[] calldata catalogueEntry) internal {
        if (_theCatalogue[tokenId].signature != 0) //on-chain
            require(_theCatalogue[tokenId].signature == _generateSignature(catalogueEntry) , "NO_SIGNATURE_MATCH");

        _safeMint(_msgSender(), tokenId); 

        if (_theCatalogue[tokenId].signature != 0) { //on-chain
            _theCatalogue[tokenId].name = catalogueEntry[0];
            _theCatalogue[tokenId].description = catalogueEntry[1];
            _theCatalogue[tokenId].image = catalogueEntry[2];
            for(uint i=3; i < catalogueEntry.length; i++) {
                _theCatalogue[tokenId].attributes[i - 3] = catalogueEntry[i];
            }
        }
        _collections[_getCollectionId(tokenId)].circulating++;
    }

    function getCollectionId(uint256 tokenId) external view returns (uint256) {
        require(ownerOf(tokenId) != address(0));
        
        return _getCollectionId(tokenId);
    }

    function _getCollectionId(uint256 tokenId) internal pure returns (uint256) {
        return tokenId / SEPARATOR;
    }


    function getAttributes(uint256 tokenId, uint256 index) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].attributes[index];
    }

    function getName(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].name;
    }

    function getDescription(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].description;
    }

    function getImage(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].image;
    }

    function getSignature(uint256 tokenId) external view returns (bytes32) {
        require(ownerOf(tokenId) != address(0));
        
        return _theCatalogue[tokenId].signature;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(metadataAddress != address(0), "NO_METADATA_ADDRESS");
        require(ownerOf(tokenId) != address(0));

        return IMoPArMetadata(metadataAddress).tokenURI(tokenId);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setImage(uint256 tokenId, string calldata image) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].image = image;
    }

    function setAttributes(uint256 tokenId, uint256 index, string calldata newEntry) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].attributes[index] = newEntry;
    }

    function setName(uint256 tokenId, string calldata name) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].name = name;
    }

    function setDescription(uint256 tokenId, string calldata description) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].description = description;
    }

    function setSignature(uint256 tokenId, bytes32 signature) external onlyRole(MANAGER_ROLE) {
        require(_theCatalogue[tokenId].signature.length > 0, "INVALID_TOKENID");
        _theCatalogue[tokenId].signature = signature;
    }

    function getCollection(uint256 collectionId) external view returns (bool exists, string memory name, string memory artist, bool paused, uint128 max, uint256 price, uint128 circulating) {
        name = _collections[collectionId].name;
        artist = _collections[collectionId].artist;
        paused = !_isCollectionUnpaused.get(collectionId);
        max = _collections[collectionId].max;
        price = _collections[collectionId].price;
        circulating = _collections[collectionId].circulating;
        exists = bytes(_collections[collectionId].name).length != 0 && bytes(_collections[collectionId].artist).length > 0;
    }

    function getSignatures(uint256 collectionId) external view onlyRole(MANAGER_ROLE) returns (bytes32[] memory signatures, uint256[] memory tokenIds) {
        uint256 tokenId = (collectionId * SEPARATOR);
        tokenIds = new uint256[](_collections[collectionId].max);
        signatures = new bytes32[](_collections[collectionId].max);
        for (uint i = 0; i < _collections[collectionId].max; i++) {
            tokenIds[i] = tokenId + i;
            signatures[i] = _theCatalogue[tokenId+i].signature;
        }
    }

    function createCollection(string calldata name_, string calldata artist_, uint256 price_, bytes32[] calldata signatures_) external onlyRole(MANAGER_ROLE) {
        require(signatures_.length < SEPARATOR); //avoid writing over next collection's tokens

        _collections[_nextCollectionId] = Collection({name:name_, artist:artist_, price:price_, circulating:0, max:uint128(signatures_.length)});
        uint256 tokenId = (_nextCollectionId * SEPARATOR);
        
        for (uint i=0; i < signatures_.length; i++) {
            if (signatures_[i] != keccak256(abi.encodePacked("offchain"))) {
                _theCatalogue[tokenId + i].signature = signatures_[i];
            }
        }
        emit CollectionCreated(_nextCollectionId++);
    }

    function unpauseCollection(uint256 collectionId, bool shouldUnpause) onlyRole(MANAGER_ROLE) external {
        require(collectionId < _nextCollectionId, "INVALID_COLLECTION_ID");
        if (shouldUnpause) 
            _isCollectionUnpaused.set(collectionId);
        else 
            _isCollectionUnpaused.unset(collectionId);
    }

    // need to specify in units of 1e18 
    function setPriceForToken(uint256 tokenId, uint256 newPrice) external onlyRole(MANAGER_ROLE) {
        _theCatalogue[tokenId].price = newPrice;
    }     

    function setStoreOpen(bool newStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isMuseumOpen = newStatus;
    }     

    function setMetadataAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, addr);
        metadataAddress = addr;
    }

    function setWhitelist(address minter) external onlyRole(MANAGER_ROLE)  {
        whitelist[minter] = 888; //wildcard for any token
    }
    
    function setWhitelistForToken(address minter, uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        whitelist[minter] = tokenId;
    }

    function unsetWhitelist(address minter) external onlyRole(MANAGER_ROLE) {
        delete whitelist[minter];
    }

    function setManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    function unsetManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    function _generateSignature(string[] calldata catalogueEntry) private pure returns (bytes32) {
        string memory data = string(abi.encodePacked("permuted: "));
        for (uint i=0; i<catalogueEntry.length; i++) {
            data = string(abi.encodePacked(data, catalogueEntry[i]));    
        }
        return
            keccak256(abi.encodePacked(data));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NOT_OWNER_OR_APPROVED");
        super._burn(tokenId);
    }

}