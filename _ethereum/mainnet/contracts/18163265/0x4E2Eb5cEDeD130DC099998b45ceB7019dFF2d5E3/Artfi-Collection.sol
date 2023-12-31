// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Counters.sol";
import "./draft-EIP712Upgradeable.sol";
// import "./ECDSA.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Artfi-IStaking.sol";

struct NftData {
    string uri;
    uint256 fractionId;
    address[] creators;
    uint256[] royalties;
    bool isFirstSale;
}

struct MintData {
    string uri;
    uint256 fractionId;
    address seller;
    address buyer;
    address[] creators;
    uint256[] royalties;
    bool isFirstSale;
}

struct BridgeData {
    address buyer;
    address otherTokenAddress;
    string uri;
    bool locked;
}

struct WhiteList {
    address user;
    bool value;
}

/** @title  Collection Contract
 *  @dev Collection Contract is a implementation contract of both access control contract and ERC721 contract
 * which helps creators to manage there NFTs as a separate collection.
 */

contract ArtfiCollectionV2 is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    ERC721Upgradeable,
    ERC2981Upgradeable
{
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;
    // using ECDSA for bytes32;
    uint256 public version;
    string private _collectionName;
    string private _description;
    string private _imageUri;
    string private _baseTokenURI;
    uint256 private maxBatchSize;
    uint256 private collectionSize;
    uint256 private constant royaltyPercentage = 10;
    address private artfiRoyaltyContract;
    address private owner;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public remainingAmount;

    bytes32 public constant COLLECTION_OWNER_ROLE =
        keccak256("COLLECTION_OWNER_ROLE");
    bytes32 public constant ARTFI_ADMIN_ROLE = keccak256("ARTFI_ADMIN_ROLE");
    bytes32 public constant ARTFI_MARKETPLACE_ROLE =
        keccak256("ARTFI_MARKETPLACE_ROLE");

    uint256 private constant PERCENT_UNIT = 1e4;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => NftData) private _nftInfos;

    mapping(address => bool) public whiteList;

    mapping(uint256 => BridgeData) private _bridging;

    mapping(uint256 => bool) private fractionIdList;

    //*********************** Events ***********************//

    event eNftData(
        string uri,
        uint256 fractionId,
        address[] creators,
        uint256[] royalties,
        bool isFirstSale
    );

    event eTokenTransfer(address from, address to, uint256 tokenId);

    event eNewMetadata(string _description, string _imageUri, string _baseURI);

    event eSaleDuration(uint256 startDate, uint256 endDate);

    event eBaseUri(string newBaseUri);

    event eTokenUriUpdated(string uri);

    event WhiteListUpdated(address indexed client, bool value);

    event TokenLocked(uint256 indexed tokenId, address indexed tokenAddress);

    // event TokenUnlocked(uint256 indexed tokenId, address indexed tokenAddress);

    //*********************** Modifiers ***********************//
    modifier isOwner() {
        if (!hasRole(COLLECTION_OWNER_ROLE, msg.sender))
            revert GeneralError("AF:104");
        _;
    }

    modifier isArtfiAdmin() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(ARTFI_ADMIN_ROLE, msg.sender)
        ) revert GeneralError("AF:102");
        _;
    }

    modifier isArtfiAdminOrOwner() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(ARTFI_ADMIN_ROLE, msg.sender) &&
            !hasRole(COLLECTION_OWNER_ROLE, msg.sender)
        ) revert GeneralError("AF:107");
        _;
    }

    modifier isArtfiMarketplace() {
        if (!hasRole(ARTFI_MARKETPLACE_ROLE, msg.sender))
            revert GeneralError("AF:106");
        _;
    }

    modifier isArtfiAdminOrMarketplace() {
        if (
            !hasRole(ARTFI_MARKETPLACE_ROLE, msg.sender) &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(ARTFI_ADMIN_ROLE, msg.sender)
        ) revert GeneralError("AF:106");
        _;
    }

    modifier validatePayouts(
        address[] memory receivers_,
        uint256[] memory percentage_
    ) {
        // make sure stakeRoyalty and creators length are same.
        if (percentage_.length != receivers_.length)
            revert GeneralError("AF:201");
        if (receivers_.length <= 0) revert GeneralError("AF:202");

        // make sure all stakeRoyalty and receivers are non zero.
        uint256 sum = 0;
        for (uint256 i = 0; i < percentage_.length; i++) {
            if (percentage_[i] <= 0) revert GeneralError("AF:202");
            if (receivers_[i] == address(0)) revert GeneralError("AF:205");
            sum = sum + percentage_[i];
        }

        // make sure if percentage sum less than 100%
        if (sum >= PERCENT_UNIT) revert GeneralError("AF:203");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     * @notice Initializes the contract by setting 'name','symbol','baseURI','title','description','imageURI','coverImageURI' of collection and addresses of 'artfiAdmin','artfiMarketplace'.
     * @dev used instead of constructor.
     * @param version_ version of the collection contract.
     * @param collectionName_ The name of nft created.
     * @param baseURI_ baseUri of token.
     * @param description_ description for collection.
     * @param imageURI_ URI of the image for collection.
     * @param owner_ address of collection owner.
     * @param artfiAdmin_ address of  souq admin.
     * @param artfiMarketplace_ address of artfiMarketplace.
     * @param maxBatchSize_ maximum nunber the user can mint.
     * @param collectionSize_ number of NFTs allowed in the collection.
     */
    function initialize(
        uint256 version_,
        string memory collectionName_,
        string memory baseURI_,
        string memory description_,
        string memory imageURI_,
        address owner_,
        address artfiAdmin_,
        address artfiMarketplace_,
        address artfiRoyaltyContract_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) external initializer {
        if (
            owner_ == address(0) ||
            artfiAdmin_ == address(0) ||
            artfiMarketplace_ == address(0) ||
            artfiRoyaltyContract_ == address(0)
        ) revert GeneralError("AF:205");
        __ERC721_init("Artfi", "AF");
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, artfiAdmin_);
        _setupRole(ARTFI_ADMIN_ROLE, artfiAdmin_);
        _setupRole(COLLECTION_OWNER_ROLE, owner_);
        _setupRole(ARTFI_MARKETPLACE_ROLE, artfiMarketplace_);

        _collectionName = collectionName_;
        _description = description_;
        _imageUri = imageURI_;
        _baseTokenURI = baseURI_;
        version = version_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
        if (artfiRoyaltyContract_ == address(0)) revert GeneralError("AF:205");
        artfiRoyaltyContract = artfiRoyaltyContract_;
        owner = owner_;
        remainingAmount = collectionSize_;
    }

    /**
     * @notice updates metadata.
     * @dev only admin or owner can update the metadata.
     * @param description_ description for collection.
     * @param imageURI_ URI of the image for collection.
     * @param baseURI_ URI of coverimage for collection.
     */
    function updateMetadata(
        string memory description_,
        string memory imageURI_,
        string memory baseURI_
    ) external isArtfiAdminOrOwner {
        _description = description_;
        _imageUri = imageURI_;
        _baseTokenURI = baseURI_;

        emit eNewMetadata(description_, imageURI_, baseURI_);
    }

    /**
     * @notice Update list of whiteListed users
     * @dev Only by default admin role
     * @param _address user's address
     * @param _value whitelisted(true) or not whitelisted(false) the user
     */
    function whiteListUpdate(
        address _address,
        bool _value
    ) public isArtfiAdmin {
        whiteList[_address] = _value;
        emit WhiteListUpdated(_address, _value);
    }

    /**
     * @notice Update list of whiteListed for multiple users
     * @dev Only by default admin role
     * @param objects user's addresses and the value true/false
     */
    function updateWhiteListBatch(
        WhiteList[] calldata objects
    ) external isArtfiAdmin {
        for (uint256 i = 0; i < objects.length; i++) {
            whiteListUpdate(objects[i].user, objects[i].value);
        }
    }

    /**
     * @notice sets baseUri of token.
     * @dev only artfi admin can change uri.
     * @param baseUri_ baseuri of token.
     */
    function setBaseURI(string memory baseUri_) external isArtfiAdmin {
        if (bytes(baseUri_).length == 0) revert GeneralError("AF:204");
        _baseTokenURI = baseUri_;

        emit eBaseUri(baseUri_);
    }

    /**
     * @notice sets sale date.
     * @dev only artfi admin can set date.
     * @param startDate_ start date for public.
     * @param endDate_ end date for minting.
     */
    function setSaleDate(
        uint256 startDate_,
        uint256 endDate_
    ) external isArtfiAdmin {
        if (endDate_ <= startDate_) revert GeneralError("AF:209");
        if (startDate_ + 3600 < block.timestamp) revert GeneralError("AF:210");
        startDate = startDate_;
        endDate = endDate_;

        emit eSaleDuration(startDate_, endDate_);
    }

    /**
    *@notice  updates tokenURI 
    *@dev only admin can update token URI
    *@param tokenId_ Id of token.
    *@param uri_ URI of token.
    
     */
    function updateTokenURI(
        uint256 tokenId_,
        string memory uri_
    ) external isArtfiAdmin {
        if (bytes(uri_).length == 0) revert GeneralError("AF:204");
        if (!_exists(tokenId_)) revert GeneralError("AF:206");
        _nftInfos[tokenId_].uri = uri_;

        emit eTokenUriUpdated(uri_);
    }

    //*********************** Getter Functions ***********************//

    /**
     * @notice gets metadata of NFT.
     * @param description_ description for collection.
     * @param imageURI_ URI of the image for collection.
     * @param baseURI_ URI of coverimage for collection.
     */
    function getMetadata()
        external
        view
        returns (
            string memory description_,
            string memory imageURI_,
            string memory baseURI_
        )
    {
        description_ = _description;
        imageURI_ = string(abi.encodePacked(_baseTokenURI, _imageUri));
        baseURI_ = string(abi.encodePacked(_baseTokenURI));
    }

    /**
     *@notice checks function is called by admin.
     *@param caller_ address of caller.
     *@return isWhiteListed_ bool .
     */

    function isWhiteListed(address caller_) public view returns (bool) {
        if (whiteList[caller_]) return true;
        else return false;
    }

    /**
     *@notice returns the total count of minted tokens.
     *@return totalMinted_ count of minted tokens.
     */
    function totalMinted() public view returns (uint256 totalMinted_) {
        totalMinted_ = _tokenIdCounter.current();
    }

    /**
     *@notice returns if the quantity allowed to be minted.
     *@return true or false.
     *@param quantity.
     */
    function isQuantityAllowed(uint256 quantity) public view returns (bool) {
        if (
            ((totalMinted() + quantity) <= collectionSize) &&
            (quantity <= maxBatchSize)
        ) return true;
        else return false;
    }

    /**
     *@notice returns NFT data to corresponding tokenId in struct datatype.
     *@return nfts_ nft data within struct datatype.
     */
    function getAll() external view returns (NftData[] memory nfts_) {
        nfts_ = new NftData[](_tokenIdCounter.current());
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            nfts_[i - 1] = _nftInfos[i];
        }
    }

    /**
     *@notice returns address of the collection owner.
     *@return _owner address of the collection owner.
     */
    function getOwner() external view returns (address _owner) {
        _owner = owner;
    }

    /**
     *@notice returns informations of nft with given tokenId.
     *@param tokenId_ tokenId of NFT.
     *@return nfts_ nft details within struct datatype.
     */
    function getNftInfo(
        uint256 tokenId_
    ) external view returns (NftData memory nfts_) {
        nfts_ = _nftInfos[tokenId_];
    }

    /**
     *@notice  checks whether the tokenId exist.
     *@param tokenId_ tokenId of NFT.
     *@return exists_ boolean value related to existence of tokenId.
     */
    function exists(uint256 tokenId_) external view returns (bool exists_) {
        exists_ = _exists(tokenId_);
    }

    /**
     *@notice returns uri of created nft.
     *@dev works only if tokenId exist otherwise throws an error-AF:206'tokenId doesnot exist'.
     *@param tokenId_ tokenId of NFT.(mandatory)
     *@return uri_ uri of NFT.(mandatory)
     */

    function tokenURI(
        uint256 tokenId_
    ) public view override returns (string memory uri_) {
        if (!_exists(tokenId_)) revert GeneralError("AF:206");
        uri_ = string(abi.encodePacked(_baseTokenURI, _nftInfos[tokenId_].uri));
    }

    /**
     *@notice returns if interface is supported or not
     *@param interfaceId_ Id of interface.
     *@return bool checks whether interface used is same .
     */
    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            ERC2981Upgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId_) ||
            AccessControlUpgradeable.supportsInterface(interfaceId_) ||
            ERC2981Upgradeable.supportsInterface(interfaceId_);
    }

    /**
     *@notice checks given contract is a collection contract.
     *@return bool .
     */

    function isArtfiCollectionContract() external pure returns (bool) {
        return true;
    }

    /**
     *@notice global royalties
     *@dev this function can only be called from any marketplace.
     *@param tokenId.
     *@param salePrice.
     *@return receiver is the address to receive the royalty, royaltyAmount is the amount of royalty
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) public view override returns (address receiver, uint256 royaltyAmount) {
        return (artfiRoyaltyContract, (salePrice * royaltyPercentage) / 100);
    }

    //*********************** Setter Functions ***********************//
    /**
     *@notice mints NFT
     *@dev this function can only be called from marketplace contract.
     *@param mintData_ contains uri, creater addresses, royalties percentage, minter address.
     *@return tokenId_ tokenId of NFT.
     */
    function mint(
        MintData memory mintData_
    )
        external
        nonReentrant
        isArtfiMarketplace
        validatePayouts(mintData_.creators, mintData_.royalties)
        returns (uint256 tokenId_)
    {
        if (!hasRole(ARTFI_ADMIN_ROLE, mintData_.seller))
            revert GeneralError("AF:104");

        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        _safeMint(mintData_.buyer, tokenId_);
        remainingAmount = remainingAmount - 1;
        
    }

    /**
     *@notice updates royaltyfee for creators.
     *@param tokenId_ tokenId of NFT.
     *@param creators_ address of creaters of nfts.
     *@param royalties_ Royaltyfee given to the creators.
     */
    function updateRoyalties(
        uint256 tokenId_,
        address[] calldata creators_,
        uint256[] calldata royalties_
    ) external validatePayouts(creators_, royalties_) {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            _nftInfos[tokenId_].creators[0] != msg.sender
        ) revert GeneralError("AF:107");
        _nftInfos[tokenId_].creators = creators_;
        _nftInfos[tokenId_].royalties = royalties_;
    }

    // /**
    //  * @notice This function will mint NFT on the blockchain the contract deployed to, to sync with the same collection deployed on another blockchain
    //  * @param bridgeData_ the data of the NFT in the other blockchain
    //  * @return tokenId_
    //  */

    // function adminMintBridge(
    //     BridgeData memory bridgeData_
    // ) external isArtfiAdmin returns (uint256 tokenId_) {
    //     _tokenIdCounter.increment();
    //     tokenId_ = _tokenIdCounter.current();
    //     _safeMint(bridgeData_.buyer, tokenId_);

    //     BridgeData memory bridge = _bridging[tokenId_];
    //     bridge.buyer = bridgeData_.buyer;
    //     bridge.otherTokenAddress = bridgeData_.otherTokenAddress;
    //     bridge.uri = bridgeData_.uri;
    //     bridge.locked = bridgeData_.locked;

    //     emit TokenLocked(tokenId_, address(this));
    // }

    // /**
    //  * @notice this function allow Artfi to lock the NFT in order to bridge it to another blockchain
    //  * @param tokenId_ token Id in the current blockchain
    //  * @param otherTokenAddress collection smart contract address on the other blockchain
    //  * @param owner_ current owner of the NFT
    //  */
    // function bridgeNft(
    //     uint256 tokenId_,
    //     address otherTokenAddress,
    //     address owner_
    // ) external isArtfiAdmin {
    //     BridgeData memory bridge = _bridging[tokenId_];
    //     if (bridge.locked) revert GeneralError("AF:208");
    //     bridge.buyer = owner_;
    //     bridge.otherTokenAddress = otherTokenAddress;
    //     bridge.uri = _nftInfos[tokenId_].uri;
    //     bridge.locked = true;

    //     emit TokenLocked(tokenId_, address(this));
    // }

    /**
     *@notice Transfers 'tokenId' token from 'from' to 'to'.
     *@dev can only called by marketplace.
     *@param from_ address of seller.
     *@param to_ address of buyer.
     *@param tokenId_ tokenId of NfT.
     */
    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) public isArtfiAdminOrMarketplace {
        _transfer(from_, to_, tokenId_);

        emit eTokenTransfer(from_, to_, tokenId_);
    }

    function transferStakedNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) external {
        if(msg.sender != artfiRoyaltyContract) revert GeneralError("AF:110");
        _transfer(from_, to_, tokenId_);

        emit eTokenTransfer(from_, to_, tokenId_);
    }

    /**
     * @notice Function to set the NFT Data when AirDropping
     * @param tokenId_ token Id
     * @param mintData_  NFT Data
     */
    function setNftData(
        uint256 tokenId_,
        MintData calldata mintData_
    )
        public
        isArtfiAdminOrMarketplace
        validatePayouts(mintData_.creators, mintData_.royalties)
    {
        if (!_exists(tokenId_)) revert GeneralError("AF:206");
        if (bytes(mintData_.uri).length == 0) revert GeneralError("AF:204");

        if (endDate < block.timestamp || startDate > block.timestamp)
            revert GeneralError("AF:308");
        if (fractionIdList[mintData_.fractionId]) revert GeneralError("AF:211");
        if (mintData_.fractionId != tokenId_) revert GeneralError("AF:212");

        fractionIdList[mintData_.fractionId] = true;

        _nftInfos[tokenId_] = NftData({
            uri: mintData_.uri,
            fractionId: mintData_.fractionId,
            creators: mintData_.creators,
            royalties: mintData_.royalties,
            isFirstSale: mintData_.isFirstSale
        });

        emit eNftData(
            mintData_.uri,
            mintData_.fractionId,
            mintData_.creators,
            mintData_.royalties,
            mintData_.isFirstSale
        );
    }

    /**
     *@notice destroys the NFT.
     *@dev Only creator or owner can burn the token otherwise throws an error-AF:104-'Not creator or Owner'.
     *@param tokenId_ TokenId of NFT to be burned.
     */
    function burn(uint256 tokenId_) external {
        if (ownerOf(tokenId_) != _msgSender()) revert GeneralError("AF:104");
        delete _nftInfos[tokenId_];
        _burn(tokenId_);
    }

    /**
     *@notice transfers the ownership of NFT.
     *@dev only onwer can transfer the ownership.
     *@param to_ address of buyer.
     */
    function transferCollectionOwnership(address to_) external isOwner {
        _setupRole(COLLECTION_OWNER_ROLE, to_);
        _revokeRole(COLLECTION_OWNER_ROLE, msg.sender);
    }
}
