// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Counters.sol";

struct NftData {
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    bool isFirstSale;
}

struct MintData {
    string uri;
    address minter;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    bool isFirstSale;
}

/** @title Niftysouq721 contract .
 * @dev NiftySouq721 is a implementation contract of both access control contract and ERC721 contract.
 */

contract NiftySouq721V4 is ERC721Upgradeable, AccessControlUpgradeable {
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;

    //*********************** Declarations ***********************//
    string private _baseTokenURI;
    address private _niftyMarketplace;
    address private _owner; // unused variable

    uint256 private constant PERCENT_UNIT = 1e4;
    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => NftData) private nftInfos;

    //*********************** Modifiers ***********************//
    modifier isAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert GeneralError("NS:101");
        _;
    }

    modifier isNiftyMarketplace() {
        if (msg.sender != _niftyMarketplace) revert GeneralError("NS:106");
        _;
    }

    modifier validatePayouts(
        address[] calldata receivers_,
        uint256[] calldata percentage_
    ) {
        // make sure revenues and creators length are same.
        if (percentage_.length != receivers_.length)
            revert GeneralError("NS:201");

        // make sure all revenues and receivers are non zero.
        uint256 sum = 0;
        for (uint256 i = 0; i < percentage_.length; i++) {
            if (percentage_[i] <= 0) revert GeneralError("NS:202");
            if (receivers_[i] == address(0)) revert GeneralError("NS:205");
            sum = sum + percentage_[i];
        }

        // make sure if percentage sum less than 100%
        if (sum >= PERCENT_UNIT) revert GeneralError("NS:203");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @dev used instead of constructor.
     * @param name_ The name of nft created.
     * @param symbol_ The symbol of nft created.
     */

    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC721_init(name_, symbol_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     *@notice sets configuration of token with baseUri and address of niftySouqMarketplace.
     *@dev only admin can update token URI and restricting that only niftySouqMarketplace contract can do certain functionalities.
     *@param baseUri_ base URI of the token.
     *@param niftySouqMarketplace_ address of niftysouqmarketplace contract.
     */

    function setConfiguration(
        string memory baseUri_,
        address niftySouqMarketplace_
    ) external isAdmin {
        if (
            keccak256(abi.encodePacked(baseUri_)) !=
            keccak256(abi.encodePacked(""))
        ) _baseTokenURI = baseUri_;

        if (niftySouqMarketplace_ != address(0))
            _niftyMarketplace = niftySouqMarketplace_;
    }

    /**
     *@notice  updates tokenURI
     *@dev only admin can update token URI.
     *@param tokenId_ Id of token.(mandatory)
     *@param uri_ URI of token.(mandatory)
     */

    function updateTokenURI(uint256 tokenId_, string memory uri_)
        external
        isAdmin
    {
        if (
            keccak256(abi.encodePacked(uri_)) == keccak256(abi.encodePacked(""))
        ) revert GeneralError("NS:204");
        if (!_exists(tokenId_)) revert GeneralError("NS:206");
        nftInfos[tokenId_].uri = uri_;
    }

    //*********************** Getter Functions ***********************//
    /**
     *@notice  returns the configuration with baseUri and address of niftySouqMarketplace.
     *@return baseUri_ the baseUri of token.
     *@return niftySouqMarketplace_ address of niftySouqMarketplace.
     */

    function getConfiguration()
        public
        view
        returns (string memory baseUri_, address niftySouqMarketplace_)
    {
        baseUri_ = _baseTokenURI;
        niftySouqMarketplace_ = _niftyMarketplace;
    }

    /**
     *@notice  returns the total count of minted tokens.
     *@return totalMinted_ count of minted tokens.
     */

    function totalMinted() public view returns (uint256 totalMinted_) {
        totalMinted_ = _tokenIdCounter.current();
    }

    /**
     *@notice  returns NFT data to corresponding tokenId in struct datatype.
     *@return nfts_ nft data within struct datatype.
     */

    function getAll() public view returns (NftData[] memory nfts_) {
        for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
            nfts_[i] = nftInfos[i];
        }
    }

    /**
     *@notice returns informations of nft with given tokenId.
     *@param tokenId_ tokenId of NFT.
     *@return nfts_ nft details within struct datatype.
     */

    function getNftInfo(uint256 tokenId_)
        public
        view
        returns (NftData memory nfts_)
    {
        nfts_ = nftInfos[tokenId_];
    }

    /**
     *@notice checks whether the tokenId exist.
     *@param tokenId_ tokenId of NFT.
     *@return exists_ boolean value related to existence of tokenId.
     */

    function exists(uint256 tokenId_) public view returns (bool exists_) {
        exists_ = _exists(tokenId_);
    }

    /**
     *@notice returns uri of created nft.
     *@dev function works only if tokenId exist otherwise throws an error-NS:206'tokenId doesnot exist'.
     *@param tokenId_ tokenId of NFT.
     *@return uri_ uri of NFT.
     */

    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory uri_)
    {
        if (!_exists(tokenId_)) revert GeneralError("NS:206");
        uri_ = string(abi.encodePacked(_baseTokenURI, nftInfos[tokenId_].uri));
    }

    /**
     *@notice returns if interface is supported or not.
     *@param interfaceId_ Id of interface.
     *@return bool checks whether interface used is same .
     */

    function supportsInterface(bytes4 interfaceId_)
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

    //*********************** Setter Functions ***********************//
    /**
     *@notice mints NFT
     *@dev this function can only be called from marketplace contract.
     *@param mintData_ contains uri, creater addresses, royalties percentage, investors addresses, revenue percentage,minter address.
     *@return tokenId_ tokenId of NFT.
     */
    function mint(MintData calldata mintData_)
        external
        validatePayouts(mintData_.investors, mintData_.revenues)
        validatePayouts(mintData_.creators, mintData_.royalties)
        isNiftyMarketplace
        returns (uint256 tokenId_)
    {
        if (
            keccak256(abi.encodePacked(mintData_.uri)) ==
            keccak256(abi.encodePacked(""))
        ) revert GeneralError("NS:204");
        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        _safeMint(mintData_.minter, tokenId_);

        nftInfos[tokenId_] = NftData(
            mintData_.uri,
            mintData_.creators,
            mintData_.royalties,
            mintData_.investors,
            mintData_.revenues,
            mintData_.isFirstSale
        );
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
            nftInfos[tokenId_].creators[0] != msg.sender
        ) revert GeneralError("NS:107");
        nftInfos[tokenId_].creators = creators_;
        nftInfos[tokenId_].royalties = royalties_;
    }

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
    ) external isNiftyMarketplace {
        _transfer(from_, to_, tokenId_);
        if (nftInfos[tokenId_].isFirstSale)
            nftInfos[tokenId_].isFirstSale = false;
    }

    /**
     *@notice destroys the NFT.
     *@dev Only creator or owner can burn the token otherwise throws an error-NS:104-'Not creator or Owner'.
     *@param tokenId_ TokenId of NFT to be burned.
     */

    function burn(uint256 tokenId_) external {
        if (ownerOf(tokenId_) != _msgSender()) revert GeneralError("NS:104");
        delete nftInfos[tokenId_];
        _burn(tokenId_);
    }
}
