// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./BitMaps.sol";
import "./IERC2981.sol";
import "./MerkleProof.sol";

interface IMoPArMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function beforeTokenTransfer(address from, address to, uint256 tokenId) external;
}

/***************************************************************************************
 *                     __  ___                                         ____            *
 *                    /  |/  /_  __________  __  ______ ___     ____  / __/            *
 *                   / /|_/ / / / / ___/ _ \/ / / / __ `__ \   / __ \/ /_              *
 *                  / /  / / /_/ (__  )  __/ /_/ / / / / / /  / /_/ / __/              *
 *                 /_/  /_/\__,_/____/\___/\__,_/_/ /_/ /_/   \____/_/                 *
 *             ____                            __           __   ___         __        *
 *            / __ \___  _________ ___  __  __/ /____  ____/ /  /   |  _____/ /_       *
 *           / /_/ / _ \/ ___/ __ `__ \/ / / / __/ _ \/ __  /  / /| | / ___/ __/       *
 *          / ____/  __/ /  / / / / / / /_/ / /_/  __/ /_/ /  / ___ |/ /  / /_         *
 *         /_/    \___/_/  /_/ /_/ /_/\__,_/\__/\___/\__,_/  /_/  |_/_/   \__/         *
****************************************************************************************/
contract MoPArV2 is 
    Initializable, 
    OwnableUpgradeable, 
    AccessControlEnumerableUpgradeable, 
    ERC721EnumerableUpgradeable, 
    IERC2981 
{
    using BitMaps for BitMaps.BitMap;

    struct Collection {
        string name;
        string artist;
        uint128 circulating;
        uint128 max;
        uint256 price;
        address payable artistWallet;
        uint128 artistMintBasis; //in basis points (ie 5.0% = 500)
        address royaltyWallet;
        uint128 royaltyBasis; //in basis points (ie 5.0% = 500)
        address customContract;
        bool offChain;
    }

    struct Entry {
        bytes32 signature;
        uint256 price;
        string name;
        string description;
        string image;
        string[20] attributes;
    }

    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    uint256 private constant SEPARATOR = 10**4;

    mapping(address => uint256) public whitelist;
    mapping(uint256 => Collection) private _collections;
    mapping(uint256 => Entry) private _theCatalogue;

    BitMaps.BitMap private _isCollectionUnpaused;
    bool public isMuseumOpen;
    uint256 private _nextCollectionId;
    address public metadataAddress;
    bytes32 private _whitelistMerkleRoot;
    address public defaultRoyaltyAddress;

    /**********************************************************************************
     *                                     Events                                     *
     **********************************************************************************/
    event CollectionCreated(uint256 collectionId);
    event CollectionUpdated(uint256 collectionId);
    event MintedArt(uint256 tokenId, string[] catalogueEntry);

    /**********************************************************************************
     *                                Minting Functions                               *
     **********************************************************************************/
    function claimArt(uint256 tokenId, string[] calldata catalogueEntry) external payable {
        require(isMuseumOpen == true, "MUSEUM_CLOSED");
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        require(_isCollectionUnpaused.get(_getCollectionId(tokenId)), "COLLECTION_IS_PAUSED");
        
        require(_getPrice(tokenId) <= msg.value, "INSUFFICIENT_ETH");

        _mint(tokenId, catalogueEntry);

        //split mint fee based on artistSplit with collection artistWallet address
        if (_collections[_getCollectionId(tokenId)].artistWallet != address(0)) {
            _collections[_getCollectionId(tokenId)].artistWallet.transfer(
                (msg.value * _collections[_getCollectionId(tokenId)].artistMintBasis)/10000
            );
        }
    }

    function whitelistClaim(uint256 tokenId, string[] calldata catalogueEntry) external payable {
        require(isMuseumOpen == true, "MUSEUM_CLOSED");
        require(whitelist[msg.sender] == 888 || tokenId == whitelist[msg.sender], "INVALID_WHITELIST"); //888 is wildcard for any token
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
    
        require(_getPrice(tokenId) <= msg.value, "INSUFFICIENT_ETH");

        _mint(tokenId, catalogueEntry);
        whitelist[msg.sender] = 0;
    }

    function merkletreeClaim(bytes32[] calldata merkleProof, uint256 tokenId, string[] calldata catalogueEntry) external payable {
        require(isMuseumOpen == true, "MUSEUM_CLOSED");
        require(verifyMerkleProof(merkleProof), "INVALID_WHITELIST");
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
    
        require(_getPrice(tokenId) <= msg.value, "INSUFFICIENT_ETH");

        _mint(tokenId, catalogueEntry);
    }

    function daoClaim(uint256 tokenId, string[] calldata catalogueEntry) external onlyRole(MANAGER_ROLE) {
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        
        _mint(tokenId, catalogueEntry);
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

        emit MintedArt(tokenId, catalogueEntry);
    }

    /**********************************************************************************
     *                          On-Chain NFT Setters/Getters                          *
     **********************************************************************************/
    function setImage(uint256 tokenId, string calldata image) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].image = image;
    }
    function getImage(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].image;
    }

    function setAttributes(uint256 tokenId, uint256 index, string calldata newEntry) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].attributes[index] = newEntry;
    }
    function getAttributes(uint256 tokenId, uint256 index) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].attributes[index];
    }

    function setName(uint256 tokenId, string calldata name) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].name = name;
    }
    function getName(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");

        return _theCatalogue[tokenId].name;
    }

    function setDescription(uint256 tokenId, string calldata description) external onlyRole(MANAGER_ROLE) {
        require(ownerOf(tokenId) != address(0));
        _theCatalogue[tokenId].description = description;
    }
    function getDescription(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0));
        require(_theCatalogue[tokenId].signature != 0, "OFF-CHAIN ENTRY");
        
        return _theCatalogue[tokenId].description;
    }

    function setSignature(uint256 tokenId, bytes32 signature) external onlyRole(MANAGER_ROLE) {
        require(_theCatalogue[tokenId].signature.length > 0, "INVALID_TOKENID");
        _collections[_getCollectionId(tokenId)].max = signature.length;
        _theCatalogue[tokenId].signature = signature;
    }
    function getSignature(uint256 tokenId) external view returns (bytes32) {
        require(ownerOf(tokenId) != address(0));
        
        return _theCatalogue[tokenId].signature;
    }

    // need to specify in units of 1e18 
    function setPriceForToken(uint256 tokenId, uint256 newPrice) external onlyRole(MANAGER_ROLE) {
        _theCatalogue[tokenId].price = newPrice;
    }
    function getPrice(uint256 tokenId) external view returns (uint256) {
        require(_collections[_getCollectionId(tokenId)].circulating < _collections[_getCollectionId(tokenId)].max, "INVALID_TOKEN_ID");
        
        return _getPrice(tokenId);
    }

    function getCollectionId(uint256 tokenId) external view returns (uint256) {
        require(ownerOf(tokenId) != address(0));
        
        return _getCollectionId(tokenId);
    }

    function _getPrice(uint256 tokenId) internal view returns (uint256) {
        if (_theCatalogue[tokenId].price != 0)
            return _theCatalogue[tokenId].price;
        else
            return _collections[_getCollectionId(tokenId)].price;
    }

    function _getCollectionId(uint256 tokenId) internal pure returns (uint256) {
        return tokenId / SEPARATOR;
    }

    /**********************************************************************************
     *                           Collection Setters/Getters                           *
     **********************************************************************************/
    function getCollection(uint256 collectionId) external view returns (bool paused, Collection memory collection) {
        return (!_isCollectionUnpaused.get(collectionId), _collections[collectionId]);
    }
    function setCollection(
        uint256 collectionId_,
        Collection memory collection_
    )  
        external 
        onlyRole(MANAGER_ROLE)
    {
        //prevent overwriting generated data
        collection_.max = _collections[collectionId_].max;
        collection_.circulating = _collections[collectionId_].circulating;

        _collections[collectionId_] = collection_;
        emit CollectionUpdated(collectionId_);
    }

    function getSignatures(uint256 collectionId) 
        external 
        view 
        onlyRole(MANAGER_ROLE) 
    returns (bytes32[] memory signatures, uint256[] memory tokenIds) {
        uint256 tokenId = (collectionId * SEPARATOR);
        tokenIds = new uint256[](_collections[collectionId].max);
        signatures = new bytes32[](_collections[collectionId].max);
        for (uint i = 0; i < _collections[collectionId].max; i++) {
            tokenIds[i] = tokenId + i;
            signatures[i] = _theCatalogue[tokenId+i].signature;
        }
    }

    function createCollection(Collection memory collection, bytes32[] calldata signatures_)  
        external 
        onlyRole(MANAGER_ROLE)
    {
        require(signatures_.length < SEPARATOR); //avoid writing over next collection's tokens
        //ensure correct defaults are set
        collection.max = uint128(signatures_.length);
        collection.circulating = 0;

        _collections[_nextCollectionId] = collection;
        if (!collection.offChain) {
            uint256 tokenId = (_nextCollectionId * SEPARATOR);

            for (uint i=0; i < signatures_.length; i++) {
                if (signatures_[i] != "") {
                    _theCatalogue[tokenId + i].signature = signatures_[i];
                }
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
    /**********************************************************************************
     *                    Access List/Merkel Tree Admin Functions                     *
     **********************************************************************************/
    function setWhitelist(address minter) external onlyRole(MANAGER_ROLE)  {
        whitelist[minter] = 888; //wildcard for any token
    }
    
    function setWhitelistForToken(address minter, uint256 tokenId) external onlyRole(MANAGER_ROLE) {
        whitelist[minter] = tokenId;
    }

    function unsetWhitelist(address minter) external onlyRole(MANAGER_ROLE) {
        delete whitelist[minter];
    }

    function setWhitelistMerkleRoot(bytes32 newRoot) external onlyRole(MANAGER_ROLE) {
        _whitelistMerkleRoot = newRoot;
    }

    function verifyMerkleProof(bytes32[] calldata proof) public view returns (bool) {
        return MerkleProof.verify(proof, _whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }

    /**********************************************************************************
     *                                Admin Functions                                 *
     **********************************************************************************/
    function setStoreOpen(bool newStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isMuseumOpen = newStatus;
    }     

    function setMetadataAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, addr);
        metadataAddress = addr;
    }

    function setManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MANAGER_ROLE, manager);
    }

    function unsetManager(address manager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MANAGER_ROLE, manager);
    }

    function setDefaultRoyaltyAddress(address newAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultRoyaltyAddress = newAddress;
    }

    function recordArt(uint256 tokenId, string[] calldata catalogueEntry)
        external 
        onlyRole(MANAGER_ROLE)
    {
         emit MintedArt(tokenId, catalogueEntry);
    }

    function _generateSignature(string[] calldata catalogueEntry) private pure returns (bytes32) {
        string memory data = string(abi.encodePacked("permuted: "));
        for (uint i=0; i<catalogueEntry.length; i++) {
            data = string(abi.encodePacked(data, catalogueEntry[i]));    
        }
        return
            keccak256(abi.encodePacked(data));
    }

    /**********************************************************************************
     *                           Overridden/Base Functions                            *
     **********************************************************************************/
    function initialize(bool isMuseumOpen_, address adminAddress_) public initializer {
        __ERC721_init("Museum Of Permuted Art", "MOPAR");
        __Ownable_init();

        _nextCollectionId = 1;
        isMuseumOpen = isMuseumOpen_;
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress_);
        defaultRoyaltyAddress = adminAddress_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "NOT_OWNER_OR_APPROVED");
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(metadataAddress != address(0), "NO_METADATA_ADDRESS");
        require(ownerOf(tokenId) != address(0));

        if (_collections[_getCollectionId(tokenId)].customContract != address(0)) {
            return IMoPArMetadata(_collections[_getCollectionId(tokenId)].customContract).tokenURI(tokenId);
        } else {
            return IMoPArMetadata(metadataAddress).tokenURI(tokenId);
        }
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (_collections[_getCollectionId(_tokenId)].royaltyWallet == address(0)) {
            return (defaultRoyaltyAddress, (_salePrice * 1000) / 10000);    
        }
        return (_collections[_getCollectionId(_tokenId)].royaltyWallet, (_salePrice * _collections[_getCollectionId(_tokenId)].royaltyBasis) / 10000);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (_collections[_getCollectionId(tokenId)].customContract != address(0)) {
            IMoPArMetadata(_collections[_getCollectionId(tokenId)].customContract).beforeTokenTransfer(from, to, tokenId);
        }
    }
} 