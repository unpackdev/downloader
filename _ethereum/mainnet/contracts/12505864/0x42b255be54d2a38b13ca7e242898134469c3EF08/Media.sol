// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.6.8;
pragma experimental ABIEncoderV2;

import "./ERC721Burnable.sol";
import "./ERC721.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Decimal.sol";
import "./IMarket.sol";
import "./IMedia.sol";

/**
 * @title A media value system, with perpetual equity to creators
 * @notice This contract provides an interface to mint media with a market
 * owned by the creator.
 */
contract Media is IMedia, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* *******
     * Events
     * *******/

    event CurrentPriceChanged(
        uint256 _currentPrice        
    );

    event DeveloperChanged(
        address _developer        
    );

    event SetMessage(
        address indexed _from,
        uint256 _token,
        string _msg
    );

    /* *******
     * Globals
     * *******
     */

    // Hash of 
    uint256 public constant COLLECTION_LIBRARY_HASH = 0x152d4f1109f051d3d477f8179dbbc746f65e1abb0d11d796b1943f5ca596c245;

    // Developer address
    address public constant INITIAL_DEVELOPER_ADDRESS = 0xDE89fb5bd8f420301fAB3930fAaEf185776c4b07;

    // Initial cryptolovelock price
    uint256 public constant INITIAL_PRICE = 0.04e18;

    // First 1089 tokens are reserved for future sales
    uint16 public constant RESERVED_FOR_FUTURE_SALES = 1089;

    // Total number of token available
    uint256 public constant TOTAL_SUPPLY = 10890;

    // Current price for Cryptolovelock
    uint256 public crytolovelockPrice;

    // Developer of Cryptolovelocks
    address public developer;

    // When true the owner of the token specified by the key
    // can set the love note: when owner set a love note this flag is
    // resetted.
    // We set this flag to true when token is transferred.
    mapping(uint256 => bool) public _canSetMessage;

    // Address for the market
    address public marketContract;

    // Mapping from token to previous owner of the token
    mapping(uint256 => address) public previousTokenOwners;

    // Mapping from token id to creator address
    mapping(uint256 => address) public tokenCreators;

    // Mapping from creator address to their (enumerable) set of created tokens
    mapping(address => EnumerableSet.UintSet) private _creatorTokens;

    // Mapping from token id to sha256 hash of content
    mapping(uint256 => bytes32) public tokenContentHashes;

    // Mapping from token id to sha256 hash of metadata
    mapping(uint256 => bytes32) public tokenMetadataHashes;

    // Mapping from token id to metadataURI
    mapping(uint256 => string) private _tokenMetadataURIs;

    // Mapping from contentHash to bool
    mapping(bytes32 => bool) private _contentHashes;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *     bytes4(keccak256('tokenMetadataURI(uint256)')) == 0x157c3df9
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd ^ 0x157c3df9 == 0x4e222e66
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x4e222e66;

    /* *********
     * Modifiers
     * *********
     */

    /**
     * @notice Require that the token has not been burned and has been minted
     */
    modifier onlyExistingToken(uint256 tokenId) {
        require(_exists(tokenId), "Media: nonexistent token");
        _;
    }

    /**
     * @notice Require that the token has had a content hash set
     */
    modifier onlyTokenWithContentHash(uint256 tokenId) {
        require(
            tokenContentHashes[tokenId] != 0,
            "Media: token does not have hash of created content"
        );
        _;
    }

    /**
     * @notice Require that the token has had a metadata hash set
     */
    modifier onlyTokenWithMetadataHash(uint256 tokenId) {
        require(
            tokenMetadataHashes[tokenId] != 0,
            "Media: token does not have hash of its metadata"
        );
        _;
    }

    /**
     * @notice Ensure that the provided spender is the approved or the owner of
     * the media for the specified tokenId
     */
    modifier onlyApprovedOrOwner(address spender, uint256 tokenId) {
        require(
            _isApprovedOrOwner(spender, tokenId),
            "Media: Only approved or owner"
        );
        _;
    }

    /**
     * @notice Ensure the token has been created (even if it has been burned)
     */
    modifier onlyTokenCreated(uint256 tokenId) {
        require (tokenCreators[tokenId] != address(0x0), "Media: token with that id does not exist");
        _;
    }

    /**
     * @notice Ensure that the provided URI is not empty
     */
    modifier onlyValidURI(string memory uri) {
        require(
            bytes(uri).length != 0,
            "Media: specified uri must be non-empty"
        );
        _;
    }

    /**
     * @notice On deployment, set the market contract address and register the
     * ERC721 metadata interface
     */
    constructor(address marketContractAddr) public ERC721("Cryptolovelocks", "LOCK") {
        marketContract = marketContractAddr;
        crytolovelockPrice = INITIAL_PRICE;
        developer = INITIAL_DEVELOPER_ADDRESS;
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    /* **************
     * View Functions
     * **************
     */

    /**
     * Constant BidShares for Cryptolovelocs: 5% to creator
     * the rest to the owner
     */
    function initialBidShares() public pure returns (IMarket.BidShares memory) {
        return IMarket.BidShares({
            creator: Decimal.D256(5 * Decimal.BASE),
            prevOwner: Decimal.D256(0),
            owner: Decimal.D256(95 * Decimal.BASE)
        });
    }

    function currentPrice() public view returns (uint256) {
        return crytolovelockPrice;
    }

    function setCurrentPrice(uint256 _crytolovelockPrice) public {
        require(msg.sender == developer, "Media: only developer can set the price");
        crytolovelockPrice = _crytolovelockPrice;
        emit CurrentPriceChanged(_crytolovelockPrice);
    }

    function currentDeveloper() public view returns (address) {
        return developer;
    }

    function setDeveloper(address _developer) public {
        require(msg.sender == developer, "Media: only developer can change the developer");
        developer = _developer;
        emit DeveloperChanged(_developer);
    }

    /**
     * @notice return the URI for a particular piece of media with the specified tokenId
     * @dev This function is an override of the base OZ implementation because we
     * will return the tokenURI even if the media has been burned. In addition, this
     * protocol does not support a base URI, so relevant conditionals are removed.
     * @return the URI for a token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        onlyTokenCreated(tokenId)
        returns (string memory)
    {
        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    /**
     * @notice Return the metadata URI for a piece of media given the token URI
     * @return the metadata URI for the token
     */
    function tokenMetadataURI(uint256 tokenId)
        external
        view
        override
        onlyTokenCreated(tokenId)
        returns (string memory)
    {
        return _tokenMetadataURIs[tokenId];
    }

    /* ****************
     * Public Functions
     * ****************
     */

    /**
     * Set your love message
     */
    function setLoveMessage(uint256 _tokenId, string memory _msg) public onlyApprovedOrOwner(msg.sender, _tokenId) {
        require(_canSetMessage[_tokenId], "Cryptolovelock: You already chosen your love note");
        _canSetMessage[_tokenId] = false;
        emit SetMessage(msg.sender, _tokenId, _msg);
    }

    /**
     * @notice see IMedia
     */
    function mint(uint256 tokenId, MediaData memory data)
        public
        override
        payable
        nonReentrant
    {
        if (msg.sender != developer) {
            require(msg.value >= crytolovelockPrice, "Media: price not payed");
        }
        _mintForCreator(tokenId, msg.sender, data, initialBidShares());
        if (msg.sender != developer) {
            payable(developer).transfer(msg.value);
        }
    }

    /**
     * @notice see IMedia
     */
    function auctionTransfer(uint256 tokenId, address recipient)
        external
        override
    {
        require(msg.sender == marketContract, "Media: only market contract");
        previousTokenOwners[tokenId] = ownerOf(tokenId);
        _safeTransfer(ownerOf(tokenId), recipient, tokenId, "");
    }

    /**
     * @notice see IMedia
     */
    function setAsk(uint256 tokenId, IMarket.Ask memory ask)
        public
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        IMarket(marketContract).setAsk(tokenId, ask);
    }

    /**
     * @notice see IMedia
     */
    function removeAsk(uint256 tokenId)
        external
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        IMarket(marketContract).removeAsk(tokenId);
    }

    /**
     * @notice see IMedia
     */
    function setBid(uint256 tokenId, IMarket.Bid memory bid)
        public
        override
        nonReentrant
        onlyExistingToken(tokenId)
    {
        require(msg.sender == bid.bidder, "Market: Bidder must be msg sender");
        IMarket(marketContract).setBid(tokenId, bid, msg.sender);
    }

    /**
     * @notice see IMedia
     */
    function removeBid(uint256 tokenId)
        external
        override
        nonReentrant
        onlyTokenCreated(tokenId)
    {
        IMarket(marketContract).removeBid(tokenId, msg.sender);
    }

    /**
     * @notice see IMedia
     */
    function acceptBid(uint256 tokenId, IMarket.Bid memory bid)
        public
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        IMarket(marketContract).acceptBid(tokenId, bid);
    }

    /**
     * @notice Burn a token.
     * @dev Only callable if the media owner is also the creator.
     */
    function burn(uint256 tokenId)
        public
        override
        nonReentrant
        onlyExistingToken(tokenId)
        onlyApprovedOrOwner(msg.sender, tokenId)
    {
        address owner = ownerOf(tokenId);

        require(
            tokenCreators[tokenId] == owner,
            "Media: owner is not creator of media"
        );

        _burn(tokenId);
    }

    /**
     * @notice Revoke the approvals for a token. The provided `approve` function is not sufficient
     * for this protocol, as it does not allow an approved address to revoke it's own approval.
     */
    function revokeApproval(uint256 tokenId) external override nonReentrant {
        require(
            msg.sender == getApproved(tokenId),
            "Media: caller not approved address"
        );
        _approve(address(0), tokenId);
    }

    /**
     * @notice see IMedia
     * @dev only callable by approved or owner
     */
    function updateTokenURI(uint256 tokenId, string calldata _tokenURI)
        external
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenId)
        onlyTokenWithContentHash(tokenId)
        onlyValidURI(_tokenURI)
    {
        _setTokenURI(tokenId, _tokenURI);
        emit TokenURIUpdated(tokenId, msg.sender, _tokenURI);
    }

    /**
     * @notice see IMedia
     * @dev only callable by approved or owner
     */
    function updateTokenMetadataURI(
        uint256 tokenId,
        string calldata metadataURI
    )
        external
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenId)
        onlyTokenWithMetadataHash(tokenId)
        onlyValidURI(metadataURI)
    {
        _setTokenMetadataURI(tokenId, metadataURI);
        emit TokenMetadataURIUpdated(tokenId, msg.sender, metadataURI);
    }

    /* *****************
     * Private Functions
     * *****************
     */

    /**
     * @notice Creates a new token for `creator`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_safeMint}.
     *
     * On mint, also set the sha256 hashes of the content and its metadata for integrity
     * checks, along with the initial URIs to point to the content and metadata. Attribute
     * the token ID to the creator, mark the content hash as used, and set the bid shares for
     * the media's market.
     *
     * Note that although the content hash must be unique for future mints to prevent duplicate media,
     * metadata has no such requirement.
     */
    function _mintForCreator(
        uint256 tokenId,
        address creator,
        MediaData memory data,
        IMarket.BidShares memory bidShares
    ) internal onlyValidURI(data.tokenURI) onlyValidURI(data.metadataURI) {
        require(data.contentHash != 0, "Media: content hash must be non-zero");
        require(
            _contentHashes[data.contentHash] == false,
            "Media: a token has already been created with this content hash"
        );
        require(
            data.metadataHash != 0,
            "Media: metadata hash must be non-zero"
        );
        require(!_exists(tokenId), "Media: token already exists");
        require(tokenId >= 0 && tokenId < TOTAL_SUPPLY, "Media: collection has a limited supply");
        if (creator != developer) {
            require(tokenId >= RESERVED_FOR_FUTURE_SALES, "Media: this token is left for future sales");
        }
        else {
            require(tokenId < RESERVED_FOR_FUTURE_SALES, "Media: developer can mint only token left for future sales");
        }

        _safeMint(creator, tokenId);

        _setTokenContentHash(tokenId, data.contentHash);
        _setTokenMetadataHash(tokenId, data.metadataHash);
        _setTokenMetadataURI(tokenId, data.metadataURI);
        _setTokenURI(tokenId, data.tokenURI);
        _canSetMessage[tokenId] = true;
        _creatorTokens[creator].add(tokenId);
        _contentHashes[data.contentHash] = true;

        tokenCreators[tokenId] = creator;
        previousTokenOwners[tokenId] = creator;
        IMarket(marketContract).setBidShares(tokenId, bidShares);
    }

    function _setTokenContentHash(uint256 tokenId, bytes32 contentHash)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        tokenContentHashes[tokenId] = contentHash;
    }

    function _setTokenMetadataHash(uint256 tokenId, bytes32 metadataHash)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        tokenMetadataHashes[tokenId] = metadataHash;
    }

    function _setTokenMetadataURI(uint256 tokenId, string memory metadataURI)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        _tokenMetadataURIs[tokenId] = metadataURI;
    }

    /**
     * @notice Destroys `tokenId`.
     * @dev We modify the OZ _burn implementation to
     * maintain metadata and to remove the
     * previous token owner from the piece
     */
    function _burn(uint256 tokenId) internal override {
        string memory _tokenURI = _tokenURIs[tokenId];

        super._burn(tokenId);

        if (bytes(_tokenURI).length != 0) {
            _tokenURIs[tokenId] = _tokenURI;
        }

        delete previousTokenOwners[tokenId];
    }

    /**
     * @notice transfer a token and remove the ask for it.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        IMarket(marketContract).removeAsk(tokenId);
        super._transfer(from, to, tokenId);
        _canSetMessage[tokenId] = true;
    }

}
