// SPDX-License-Identifier: GPL-3.0

/**
 * NOTE: This file is a clone of the Zora Media.sol contract from https://github.com/ourzora/core/blob/55b69346b829e88c23b20cdc565123a75fa1339c/contracts/Media.sol
 *
 * The following changes have been made:
 *
 * - Imports (except IMedia, ERC721, and ERC721Burnable which have been cloned into this repo) updated to import from @zoralabs/core
 * - Renamed Media to ZoraMedia (in require error strings too)
 * - `constructor` updated to accept name and symbol to pass to ERC271
 * - `tokenURI` added `virtual`
 * - Many changes to remove Zora's metadata and hashing paradigms. This now uses stock ERC271 functionality where `tokenURI` points to metadata JSON and, in this case, the derived contract will use tokenID to determine tokenURI rather than storing URI for each token. Also this no longer lets any user mint for themselves - only the contract owner can mint. This involved the following changes:
 *     - `_mintForCreator`: `MediaData` param, various checks for data hash, and all of the set hash/URI function calls have been removed
 *     - `_burn` updated to exclude _tokenURIs logic since we don't have those any more
 *     - Changed interface hash (from `_INTERFACE_ID_ERC721_METADATA` to `_INTERFACE_ID_ERC721`)
 *     - Functions and modifiers and class attributes removed entirely:
 *         - onlyTokenWithMetadataHash
 *         - onlyTokenWithContentHash
 *         - onlyValidURI
 *         - MINT_WITH_SIG_TYPEHASH
 *         - _tokenMetadataURIs
 *         - _contentHashes
 *         - tokenContentHashes;
 *         - tokenMetadataHashes;
 *         - mintWithSigNonces
 *         - tokenURI
 *         - updateTokenURI
 *         - updateTokenMetadataURI
 *         - tokenMetadataURI
 *         - _setTokenMetadataURI
 *         - _setTokenURI
 *         - _setTokenContentHash
 *         - _setTokenMetadataHash
 *         - mint
 *         - mintWithSig
 */

pragma solidity ^0.8.0;
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
contract ZoraMedia is IMedia, ERC721Burnable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    /* *******
     * Globals
     * *******
     */

    // Address for the market
    address public marketContract;

    // Mapping from token to previous owner of the token
    mapping(uint256 => address) public previousTokenOwners;

    // Mapping from token id to creator address
    mapping(uint256 => address) public tokenCreators;

    // Mapping from creator address to their (enumerable) set of created tokens
    mapping(address => EnumerableSet.UintSet) private _creatorTokens;

    //keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x49ecf333e5b8c95c40fdafc95c1ad136e8914a8fb55e9dc8bb01eaa83a2df9ad;

    // Mapping from address to token id to permit nonce
    mapping(address => mapping(uint256 => uint256)) public permitNonces;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5B5E139F
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x5B5E139F;

    Counters.Counter private _tokenIdTracker;

    /* *********
     * Modifiers
     * *********
     */

    /**
     * @notice Require that the token has not been burned and has been minted
     */
    modifier onlyExistingToken(uint256 tokenId) {
        require(_exists(tokenId), "ZoraMedia: nonexistent token");
        _;
    }

    /**
     * @notice Ensure that the provided spender is the approved or the owner of
     * the media for the specified tokenId
     */
    modifier onlyApprovedOrOwner(address spender, uint256 tokenId) {
        require(
            _isApprovedOrOwner(spender, tokenId),
            "ZoraMedia: Only approved or owner"
        );
        _;
    }

    /**
     * @notice Ensure the token has been created (even if it has been burned)
     */
    modifier onlyTokenCreated(uint256 tokenId) {
        require(
            _tokenIdTracker.current() > tokenId,
            "ZoraMedia: token with that id does not exist"
        );
        _;
    }

    /**
     * @notice On deployment, set the market contract address and register the
     * ERC721 metadata interface
     */
    constructor(
        string memory name,
        string memory symbol,
        address marketContractAddr
    ) public ERC721(name, symbol) {
        marketContract = marketContractAddr;
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /* ****************
     * Public Functions
     * ****************
     */

    /**
     * @notice see IMedia
     */
    function auctionTransfer(uint256 tokenId, address recipient)
        external
        override
    {
        require(
            msg.sender == marketContract,
            "ZoraMedia: only market contract"
        );
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
            "ZoraMedia: owner is not creator of media"
        );

        _burn(tokenId);
    }

    /**
     * @notice Revoke the approvals for a token. The provided `approve` function is not sufficient
     * for this protocol, as it does not allow an approved address to revoke it's own approval.
     * In instances where a 3rd party is interacting on a user's behalf via `permit`, they should
     * revoke their approval once their task is complete as a best practice.
     */
    function revokeApproval(uint256 tokenId) external override nonReentrant {
        require(
            msg.sender == getApproved(tokenId),
            "ZoraMedia: caller not approved address"
        );
        _approve(address(0), tokenId);
    }

    /**
     * @notice See IMedia
     * @dev This method is loosely based on the permit for ERC-20 tokens in  EIP-2612, but modified
     * for ERC-721.
     */
    function permit(
        address spender,
        uint256 tokenId,
        EIP712Signature memory sig
    ) public override nonReentrant onlyExistingToken(tokenId) {
        require(
            sig.deadline == 0 || sig.deadline >= block.timestamp,
            "ZoraMedia: Permit expired"
        );
        require(spender != address(0), "ZoraMedia: spender cannot be 0x0");
        bytes32 domainSeparator = _calculateDomainSeparator();

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            spender,
                            tokenId,
                            permitNonces[ownerOf(tokenId)][tokenId]++,
                            sig.deadline
                        )
                    )
                )
            );

        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);

        require(
            recoveredAddress != address(0) &&
                ownerOf(tokenId) == recoveredAddress,
            "ZoraMedia: Signature invalid"
        );

        _approve(spender, tokenId);
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
        address creator,
        IMarket.BidShares memory bidShares
    ) internal {
        uint256 tokenId = _tokenIdTracker.current();

        _safeMint(creator, tokenId);
        _tokenIdTracker.increment();
        _creatorTokens[creator].add(tokenId);

        tokenCreators[tokenId] = creator;
        previousTokenOwners[tokenId] = creator;
        IMarket(marketContract).setBidShares(tokenId, bidShares);
    }

    /**
     * @notice Destroys `tokenId`.
     * @dev We modify the OZ _burn implementation to
     * remove the previous token owner from the piece
     */
    function _burn(uint256 tokenId) internal override {
        super._burn(tokenId);
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
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view returns (bytes32) {
        uint256 chainID;
        /* solium-disable-next-line */
        assembly {
            chainID := chainid()
        }

        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("Zora")),
                    keccak256(bytes("1")),
                    chainID,
                    address(this)
                )
            );
    }
}
