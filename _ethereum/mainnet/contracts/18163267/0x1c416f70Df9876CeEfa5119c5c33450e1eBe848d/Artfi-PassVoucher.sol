// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Counters.sol";
import "./draft-EIP712Upgradeable.sol";
// import "./ECDSA.sol";
import "./ERC721AQueryableUpgradeable.sol";
import "./Artfi-ICollection.sol";
import "./console.sol";

struct NftData {
    string uri;
    bool unclaimed;
    address tokenAddress;
}

struct NftAttributes {
    bool unclaimed;
    bool airDrop;
    bool ieo;
    string image;
}

struct MintData {
    string uri;
    bool unclaimed;
    address tokenAddress;
    address seller;
    address buyer;
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

/** @title  Pass Voucher Contract
 *  @dev Collection Contract is an implementation contract of both access control contract and ERC721 contract
 * which helps creators to claim the original NFT from Artfi.
 */

contract ArtfiPassVoucherV2 is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    EIP712Upgradeable,
    ERC721Upgradeable
{
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;
    // using ECDSA for bytes32;
    uint256 public version;
    string private _voucherName;
    string private _description;
    string private _imageUri;
    string private _baseTokenURI;
    uint256 private maxBatchSize;
    uint256 private collectionSize;
    uint256 public remainingAmount;
    uint256 public startDate;
    uint256 public endDate;

    bytes32 public constant COLLECTION_OWNER_ROLE =
        keccak256("COLLECTION_OWNER_ROLE");
    bytes32 public constant ARTFI_ADMIN_ROLE = keccak256("ARTFI_ADMIN_ROLE");
    bytes32 public constant ARTFI_MARKETPLACE_ROLE =
        keccak256("ARTFI_MARKETPLACE_ROLE");

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => NftData) private _nftInfos;

    // mapping digest to keep track of claimed vouchers
    // mapping(bytes32 => bool) isVoucherClaimed;

    mapping(address => bool) public whiteList;

    mapping(uint256 => NftAttributes) private _tokenAttributes;

    mapping(uint256 => BridgeData) private _bridging;

    //*********************** Events ***********************//

    event WhiteListUpdated(address indexed client, bool value);

    event eMintPass(
        uint256 tokenId,
        address buyer,
        uint256 remainingAmount
    );

    event eTokenTransfer(address from, address to, uint256 tokenId);

    event eNewMetadata(string _description, string _imageUri, string _baseURI);

    event eClaimed(bool claimed);

    event eDroped(bool droped);

    event eSaleDuration(uint256 startDate, uint256 endDate);

    event eBaseUri(string newBaseUri);

    event eTokenUriUpdated(string uri);

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
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(ARTFI_ADMIN_ROLE, msg.sender) &&
            !hasRole(ARTFI_MARKETPLACE_ROLE, msg.sender)
        ) revert GeneralError("AF:102");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     * @notice Initializes the contract by setting 'name','symbol','baseURI','title','description','imageURI','coverImageURI' of collection and addresses of 'artfiAdmin','artfiMarketplace'.
     * @dev used instead of constructor.
     * @param version_ version of the collection contract.
     * @param voucherName_ The name of nft created.
     * @param baseURI_ baseUri of token.
     * @param description_ description for collection.
     * @param imageURI_ URI of the image for collection.
     * @param artfiAdmin_ address of  souq admin.
     * @param artfiMarketplace_ address of artfiMarketplace.
     * @param maxBatchSize_ maximum nunber the user can mint.
     * @param collectionSize_ number of NFTs allowed in the collection.
     */
    function initialize(
        uint256 version_,
        string memory voucherName_,
        string memory baseURI_,
        string memory description_,
        string memory imageURI_,
        address artfiAdmin_,
        address artfiMarketplace_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) external initializer {
        if (
            artfiAdmin_ == address(0) ||
            artfiMarketplace_ == address(0) 
        ) revert GeneralError("AF:205");
        __ERC721_init("ArtfiPass", "AFP");
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, artfiAdmin_);
        _setupRole(ARTFI_ADMIN_ROLE, artfiAdmin_);
        _setupRole(COLLECTION_OWNER_ROLE, artfiAdmin_);
        _setupRole(ARTFI_MARKETPLACE_ROLE, artfiMarketplace_);

        _voucherName = voucherName_;
        _description = description_;
        _imageUri = imageURI_;
        _baseTokenURI = baseURI_;
        version = version_;
        maxBatchSize = maxBatchSize_;
        collectionSize = collectionSize_;
        remainingAmount = collectionSize;
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

    // function updateAttributes(
    //     uint256 tokenId_,
    //     bool unclaimed_,
    //     bool airDrop_,
    //     bool ieo_
    // ) external isArtfiAdminOrMarketplace {
    //     _tokenAttributes[tokenId_].unclaimed = unclaimed_;
    //     _tokenAttributes[tokenId_].airDrop = airDrop_;
    //     _tokenAttributes[tokenId_].ieo = ieo_;
    // }

    function updateUnclaimedAttributes(
        uint256 tokenId_,
        bool unclaimed_
    ) public isArtfiAdminOrMarketplace {
        _tokenAttributes[tokenId_].unclaimed = unclaimed_;

        emit eClaimed(unclaimed_);
    }

    function updateDropAttributes(
        uint256 tokenId_,
        bool droped
    ) public isArtfiAdminOrMarketplace {
        _tokenAttributes[tokenId_].airDrop = droped;

        emit eDroped(droped);
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
    ) public isArtfiAdminOrMarketplace {
        if (bytes(uri_).length == 0) revert GeneralError("AF:204");
        if (!_exists(tokenId_)) revert GeneralError("AF:206");
        _nftInfos[tokenId_].uri = uri_;

        emit eTokenUriUpdated(uri_);
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
     * @notice gets attributes of NFT.
     * @param tokenId_ of the NFT.
     * @return _unclaimed uint256 number NFTs that the user allowed to claim, _service1 bool, _service2 bool, _certificate string.
     */
    function getTokenAttributes(
        uint256 tokenId_
    ) external view returns (bool _unclaimed, bool _airDrop, bool _ieo) {
        _unclaimed = _tokenAttributes[tokenId_].unclaimed;
        _airDrop = _tokenAttributes[tokenId_].airDrop;
        _ieo = _tokenAttributes[tokenId_].ieo;
    }

    /**
     * @notice gets unclaimed NFTs.
     * @param tokenId_ of the NFT.
     * @return _unclaimed uint256 number NFTs that the user allowed to claim.
     */
    function getUnclaimedTokens(
        uint256 tokenId_
    ) external view returns (bool _unclaimed) {
        _unclaimed = _tokenAttributes[tokenId_].unclaimed;
    }

    /**
     *@notice checks function is called by admin.
     *@param caller_ address of caller.
     *@return isWhiteListed_ bool .
     */

    function isWhiteListed(address caller_) public view returns (bool) {
        if (whiteList[caller_] == true) return true;
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
     *@notice returns number of tokens that can be mint.
     *@return remaining_ remainingAmount.
     */
    function getRemaining() external view returns (uint256 remaining_) {
        remaining_ = remainingAmount;
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
        override(AccessControlUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId_) ||
            AccessControlUpgradeable.supportsInterface(interfaceId_);
    }

    /**
     *@notice checks given contract is a collection contract.
     *@return bool.
     */

    function isArtfiCollectionContract() external pure returns (bool) {
        return true;
    }

    //*********************** Setter Functions ***********************//

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
        if(endDate_ <= startDate_) revert GeneralError("AF:209");
        if(startDate_ + 3600 < block.timestamp) revert GeneralError("AF:210");
        startDate = startDate_;
        endDate = endDate_;

        emit eSaleDuration(startDate_, endDate_);
    }

    /**
     *@notice mints NFT
     *@dev this function can only be called from marketplace contract.
     *@param mintData_ contains uri, creater addresses, royalties percentage, minter address.
     *@return tokenId_ tokenId of NFT.
     */
    function mint(
        MintData memory mintData_
    ) external isArtfiMarketplace nonReentrant returns (uint256 tokenId_) {
        if (startDate > block.timestamp) revert GeneralError("AF:301");

        if (!isWhiteListed(mintData_.buyer)) revert GeneralError("AF:129");

        if (endDate < block.timestamp) revert GeneralError("AF:308");

        if (!hasRole(ARTFI_ADMIN_ROLE, mintData_.seller))
            revert GeneralError("AF:104");
        if (bytes(mintData_.uri).length == 0) revert GeneralError("AF:204");

        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        _safeMint(mintData_.buyer, tokenId_);

        NftData storage nftData = _nftInfos[tokenId_];
        nftData.uri = mintData_.uri;
        nftData.unclaimed = mintData_.unclaimed;
        nftData.tokenAddress = mintData_.tokenAddress;

        NftAttributes storage nftAttributes = _tokenAttributes[tokenId_];
        nftAttributes.unclaimed = true;
        nftAttributes.airDrop = true;
        nftAttributes.ieo = true;
        nftAttributes.image = mintData_.uri;

        remainingAmount = remainingAmount - 1;

        emit eMintPass(tokenId_, mintData_.buyer, remainingAmount);
    }

    /**
     * @notice Function to update the metadata when the user claim the NFT off-chain
     * @param tokenIds_  array of tokenIds
     * @param uris_ array of new uri
     */
    function claimPass(
        uint256[] memory tokenIds_,
        string[] memory uris_
    ) public isArtfiAdmin {
        if (tokenIds_.length != uris_.length) revert GeneralError("AF:201");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            updateUnclaimedAttributes(tokenIds_[i], false);
            updateTokenURI(tokenIds_[i], uris_[i]);
        }
    }

    /**
     * @notice Function to update the metadata when the user claim the NFT off-chain
     * @param tokenIds_  array of tokenIds
     * @param uris_ array of new uri
     */
    function dropPass(
        uint256[] memory tokenIds_,
        string[] memory uris_
    ) public isArtfiAdmin {
        if (tokenIds_.length != uris_.length) revert GeneralError("AF:201");
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            updateDropAttributes(tokenIds_[i], false);
            updateTokenURI(tokenIds_[i], uris_[i]);
        }
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
    //  * @param owner current owner of the NFT
    //  */
    // function bridgeNft(
    //     uint256 tokenId_,
    //     address otherTokenAddress,
    //     address owner
    // ) external isArtfiAdmin {
    //     BridgeData memory bridge = _bridging[tokenId_];
    //     if (bridge.locked) revert GeneralError("AF:208");
    //     bridge.buyer = owner;
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
    ) external isArtfiMarketplace {
        if (_bridging[tokenId_].locked) revert GeneralError("AF:208");
        _transfer(from_, to_, tokenId_);

        emit eTokenTransfer(from_, to_, tokenId_);
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
        _setupRole(ARTFI_ADMIN_ROLE, to_);
        _revokeRole(ARTFI_ADMIN_ROLE, msg.sender);
        _revokeRole(COLLECTION_OWNER_ROLE, msg.sender);
    }
}
