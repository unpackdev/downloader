// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "./ERC721Burnable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract Media is ERC721Burnable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    /* *******
     * Globals
     * *******
     */

	mapping(address => bool) public minters;

    // Mapping from token id to creator address
    mapping(uint256 => address) public tokenCreators;

    // Mapping from creator address to their (enumerable) set of created tokens
    mapping(address => EnumerableSet.UintSet) private _creatorTokens;

    // Mapping from token id to sha256 hash of content
    mapping(uint256 => bytes32) public tokenContentHashes;

    // Mapping from token id to sha256 hash of metadata
    mapping(uint256 => bytes32) public tokenMetadataHashes;

    // Mapping from contentHash to bool
    mapping(bytes32 => bool) private _contentHashes;

	string private _storedBaseURI;

    Counters.Counter private _tokenIdTracker;

    event BaseURIUpdated(string _uri);

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
     * @notice Ensure that the sender is allowed to mint
     */
    modifier onlyMinters(address minter) {
        require(
            minters[minter],
            "Media: Only approved minters"
        );
        _;
    }

    constructor() ERC721("DHARMA DRAMA", "DD") {
		addMinter(msg.sender);
    }

    /* **************
     * View Functions
     * **************
     */

	function _baseURI() internal override view virtual returns (string memory) {
        return _storedBaseURI;
    }

    /* ****************
     * Public Functions
     * ****************
     */

	function addMinter(address minter) public onlyOwner {
		minters[minter] = true;
	}

	function removeMinter(address minter) external onlyOwner {
		minters[minter] = false;
	}

   /**
	* @dev ContentHash is a SHA256 hash of the media content being minted.
	*/
    function mint(bytes32 contentHash)
        public
        nonReentrant
		onlyMinters(msg.sender)
    {
        _mintForCreator(msg.sender, contentHash);
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
     * In instances where a 3rd party is interacting on a user's behalf via `permit`, they should
     * revoke their approval once their task is complete as a best practice.
     */
    function revokeApproval(uint256 tokenId) external nonReentrant {
        require(
            msg.sender == getApproved(tokenId),
            "Media: caller not approved address"
        );
        _approve(address(0), tokenId);
    }

    /**
     * @dev only callable by contract owner
     */
    function updateBaseURI(string calldata uri)
        external
        nonReentrant
        onlyValidURI(uri)
		onlyOwner
    {
        _storedBaseURI = uri;
        emit BaseURIUpdated(uri);
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
     */
    function _mintForCreator(
        address creator,
        bytes32 contentHash
    ) internal {
        require(contentHash != 0, "Media: content hash must be non-zero");
        require(
            _contentHashes[contentHash] == false,
            "Media: a token has already been created with this content hash"
        );

        uint256 tokenId = _tokenIdTracker.current();

        _safeMint(creator, tokenId);
        _tokenIdTracker.increment();
        _setTokenContentHash(tokenId, contentHash);
        EnumerableSet.add(_creatorTokens[creator], tokenId);
        _contentHashes[contentHash] = true;

        tokenCreators[tokenId] = creator;
    }

    function _setTokenContentHash(uint256 tokenId, bytes32 contentHash)
        internal
        virtual
        onlyExistingToken(tokenId)
    {
        tokenContentHashes[tokenId] = contentHash;
    }
}
