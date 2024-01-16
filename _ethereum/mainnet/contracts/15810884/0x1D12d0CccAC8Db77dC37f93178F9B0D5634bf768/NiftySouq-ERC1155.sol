// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./ERC1155Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./Counters.sol";

struct NftData {
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    address minter;
    uint256 firstSaleQuantity;
}

struct MintData {
    string uri;
    address minter;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
}

struct LazyMintData {
    string uri;
    address minter;
    address buyer;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
    uint256 soldQuantity;
}

/**
 * @title NiftySouq1155 contract.
 * @dev  NiftySouq1155 is a implementation contract of both access control contract and ERC1155 contract.
 */
contract NiftySouq1155V4 is ERC1155Upgradeable, AccessControlUpgradeable {
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;

    //*********************** Declarations ***********************//
    string private _baseTokenURI;
    address private _niftyMarketplace;
    address private _owner;

    uint256 private constant PERCENT_UNIT = 1e4;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256 => NftData) private nftInfos;
    mapping(uint256 => uint256) private _totalSupply;

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
     * @notice Initializes the contract.
     * @dev used instead of constructor.
     */

    function initialize() public initializer {
        __ERC1155_init(_baseTokenURI);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     *@notice sets configuration of token with baseUri and address of niftySouqMarketplace.
     *@dev only admin can update token URI.
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
        if (!exists(tokenId_)) revert GeneralError("NS:206");
        nftInfos[tokenId_].uri = uri_;
    }

    //*********************** Getter Functions ***********************//
    /**
     *@notice returns the total supply of tokens to corresponding tokenId.
     *@param tokenId tokenId of NFT.
     *@return totalSupply_ amount of tokens in existence.
     */
    function totalSupply(uint256 tokenId)
        public
        view
        virtual
        returns (uint256 totalSupply_)
    {
        totalSupply_ = _totalSupply[tokenId];
    }

    /**
     *@notice returns NFT data to corresponding tokenId in struct datatype.
     *@return nfts_ nft data within struct datatype.
     */
    function getAll() public view returns (NftData[] memory nfts_) {
        for (uint256 i = 1; i < _tokenIdCounter.current(); i++) {
            nfts_[i] = nftInfos[i];
        }
    }

    /**
     *@notice  returns informations of nft with given tokenId.
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
     *@param tokenId tokenId of NFT.
     *@return exists_ boolean value related to existence of tokenId.
     */
    function exists(uint256 tokenId)
        public
        view
        virtual
        returns (bool exists_)
    {
        exists_ = totalSupply(tokenId) > 0;
    }

    /**
     *@notice Returns the URI for token type 'id'.
     *@dev only if specific tokenId exist.
     *@param tokenId tokenId of NFT.
     *@return string uri of token.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!exists(tokenId)) revert GeneralError("NS:206");
        return string(abi.encodePacked(_baseTokenURI, nftInfos[tokenId].uri));
    }

    /**
     *@notice returns if interface is supported or not
     *@param interfaceId Id of interface.
     *@return bool checks whether interface used is same .
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    //*********************** Setter Functions ***********************//
    /**
     *@notice mints NFT .
     *@dev this function can only be called from marketplace contract.
     *@param mintData_ contains uri, creater addresses, royalties percentage, investors addresses, revenue percentage,minter address.
     *@return tokenId_ tokenId of NFT.
     */
    function mint(MintData calldata mintData_)
        public
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

        _mint(mintData_.minter, tokenId_, mintData_.quantity, "");

        nftInfos[tokenId_] = NftData(
            mintData_.uri,
            mintData_.creators,
            mintData_.royalties,
            mintData_.investors,
            mintData_.revenues,
            mintData_.minter,
            0
        );
        _totalSupply[tokenId_] = mintData_.quantity;
    }

    /**
     *@notice mints the NFT while purchasing.
     *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
     *@param lazyMintData_  contains contains uri, creater addresses, royalties percentage, investors addresses, revenue percentage,minter address,buyer address.
     *@return tokenId_ tokenId of NFT.
     */
    function lazyMint(LazyMintData calldata lazyMintData_)
        public
        validatePayouts(lazyMintData_.investors, lazyMintData_.revenues)
        validatePayouts(lazyMintData_.creators, lazyMintData_.royalties)
        isNiftyMarketplace
        returns (uint256 tokenId_)
    {
        _tokenIdCounter.increment();
        tokenId_ = _tokenIdCounter.current();
        uint256 balanceQuantity = lazyMintData_.quantity -
            lazyMintData_.soldQuantity;
        _mint(lazyMintData_.minter, tokenId_, balanceQuantity, "");
        _mint(lazyMintData_.buyer, tokenId_, lazyMintData_.soldQuantity, "");

        nftInfos[tokenId_] = NftData(
            lazyMintData_.uri,
            lazyMintData_.creators,
            lazyMintData_.royalties,
            lazyMintData_.investors,
            lazyMintData_.revenues,
            lazyMintData_.minter,
            balanceQuantity
        );
        _totalSupply[tokenId_] = lazyMintData_.quantity;
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
            nftInfos[tokenId_].minter != msg.sender
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
        uint256 tokenId_,
        uint256 quantity_
    ) public isNiftyMarketplace {
        _safeTransferFrom(from_, to_, tokenId_, quantity_, "");
        if (from_ == nftInfos[tokenId_].minter) {
            uint256 currentTotalSale = nftInfos[tokenId_].firstSaleQuantity +
                quantity_;
            if (currentTotalSale > _totalSupply[tokenId_]) {
                nftInfos[tokenId_].firstSaleQuantity = _totalSupply[tokenId_];
            }
        }
    }

    /**
     *@notice Destroys 'quantity' of tokens with 'id' from 'account'.
     *@dev Only creator or owner can burn the token otherwise throws an error-NS:104-'Not creator or Owner'.
     *@param account address of from account.
     *@param id tokenId of Nft to be burnt.
     *@param quantity amount of nfts .
     */
    function burn(
        address account,
        uint256 id,
        uint256 quantity
    ) public virtual {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender()))
            revert GeneralError("NS:104");
        _burn(account, id, quantity);
    }
}
