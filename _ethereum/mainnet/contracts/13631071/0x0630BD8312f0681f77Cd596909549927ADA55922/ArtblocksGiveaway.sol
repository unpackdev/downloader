// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract ArtblocksGiveaway is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    event GiveawayStarted(uint256 indexed collectionId, uint256 ends);

    event GiveawaySettled(
        uint256 indexed collectionId,
        address winner,
        uint256 tokenId,
        string seed
    );

    struct SignedTicket {
        address winner;
        uint256 collectionId;
        uint256 expires;
        string seed;
        bytes signature;
    }

    struct Collection {
        IERC721MetadataUpgradeable token;
        address owner;
        uint256[] tokenIds; // must be unique token Ids
        uint256 currentTokenIndex;
        uint256 duration;
        uint256 ends; // timestamp
    }

    /// @dev Giveaway is never stored, it's just used as return type.
    struct Giveaway {
        uint256 tokenId;
        string tokenURI;
        uint256 ends; // ends == 0 means no active giveaway
        uint256 totalTokens;
        bool ended;
    }

    Collection[] public collections;

    address public signer;

    mapping(uint256 => mapping(uint256 => bool)) internal minted;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable func-visibility
    // solhint-disable no-empty-blocks
    constructor() initializer {}

    function initialize(address _signer) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __EIP712_init("artblocks-giveaway", "1");
        signer = _signer;
    }

    modifier collectionExists(uint256 _collectionId) {
        require(_collectionId < collections.length, "Missing collection");
        _;
    }

    function createCollection(
        address _owner,
        IERC721MetadataUpgradeable _token,
        uint256[] calldata _tokenIds,
        uint256 _duration
    ) external onlyOwner nonReentrant returns (uint256) {
        collections.push(
            Collection({
                token: _token,
                tokenIds: _tokenIds,
                currentTokenIndex: 0,
                owner: _owner,
                duration: _duration,
                ends: 0
            })
        );
        return collections.length - 1;
    }

    /// @notice You might have to call `startGiveaway` again after adding more tokens
    /// @notice _tokenIds must be unique per collection
    function addTokenIds(uint256 _collectionId, uint256[] calldata _tokenIds)
        external
        nonReentrant
        onlyOwner
        collectionExists(_collectionId)
    {
        for (uint256 index = 0; index < _tokenIds.length; index++) {
            collections[_collectionId].tokenIds.push(_tokenIds[index]);
        }
    }

    function currentGiveaway(uint256 _collectionId)
        external
        view
        collectionExists(_collectionId)
        returns (Giveaway memory)
    {
        Collection memory c = collections[_collectionId];
        require(c.ends > 0, "No active giveaway");

        uint256 tokenId = c.tokenIds[c.currentTokenIndex];

        return
            Giveaway({
                tokenId: tokenId,
                tokenURI: c.token.tokenURI(tokenId),
                ends: c.ends,
                ended: block.timestamp >= c.ends, // solhint-disable not-rely-on-time
                totalTokens: c.tokenIds.length
            });
    }

    function tokenIds(uint256 _collectionId)
        external
        view
        collectionExists(_collectionId)
        returns (uint256[] memory)
    {
        return collections[_collectionId].tokenIds;
    }

    function startGiveaway(uint256 _collectionId)
        external
        collectionExists(_collectionId)
        onlyOwner
        nonReentrant
    {
        require(
            collections[_collectionId].ends == 0,
            "Giveaway already started"
        );
        _nextGiveaway(_collectionId);
    }

    function restartGiveaway(uint256 _collectionId)
        external
        collectionExists(_collectionId)
        onlyOwner
        nonReentrant
    {
        _nextGiveaway(_collectionId);
    }

    function _nextGiveaway(uint256 _collectionId) internal {
        Collection memory c = collections[_collectionId];

        // if we have tokens to give away
        if (c.tokenIds.length > c.currentTokenIndex) {
            uint256 ends = block.timestamp + c.duration; // solhint-disable not-rely-on-time
            collections[_collectionId].ends = ends;
            emit GiveawayStarted(_collectionId, ends);
            return;
        }

        collections[_collectionId].ends = 0;
    }

    function settle(SignedTicket calldata _ticket)
        external
        nonReentrant
        whenNotPaused
        collectionExists(_ticket.collectionId)
    {
        Collection memory c = collections[_ticket.collectionId];
        require(block.timestamp >= c.ends, "Giveaway didn't end, yet."); // solhint-disable not-rely-on-time
        require(c.currentTokenIndex < c.tokenIds.length, "Out of tokens");
        require(c.ends > 0, "No active giveaway");

        require(signer == _verify(_ticket), "Invalid ticket"); // hint: could be wrong signer
        require(_ticket.winner != address(0), "Can't be zero address");
        require(_ticket.expires > block.number, "Ticket expired");

        uint256 tokenId = c.tokenIds[c.currentTokenIndex];
        require(
            minted[_ticket.collectionId][tokenId] == false,
            "Already minted"
        );
        minted[_ticket.collectionId][tokenId] = true;

        collections[_ticket.collectionId].currentTokenIndex++; // advance currentTokenIndex for next mint, potentially pointing to a non-existent tokenId
        _nextGiveaway(_ticket.collectionId);

        emit GiveawaySettled(
            _ticket.collectionId,
            _ticket.winner,
            tokenId,
            _ticket.seed
        );

        c.token.transferFrom(c.owner, _ticket.winner, tokenId);
    }

    /// @dev number returned includes the current token
    function tokensLeft(uint256 _collectionId)
        external
        view
        collectionExists(_collectionId)
        returns (uint256)
    {
        Collection memory c = collections[_collectionId];
        return c.tokenIds.length - c.currentTokenIndex;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _verify(SignedTicket calldata _ticket)
        private
        view
        returns (address)
    {
        bytes32 digest = _hashTypedData(_ticket);
        return ECDSAUpgradeable.recover(digest, _ticket.signature);
    }

    function _hashTypedData(SignedTicket calldata _ticket)
        private
        view
        returns (bytes32)
    {
        // https://eips.ethereum.org/EIPS/eip-712#definition-of-typed-structured-data-%F0%9D%95%8A
        // https://docs.openzeppelin.com/contracts/4.x/api/utils#EIP712-_hashTypedDataV4-bytes32-
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "SignedTicket(address winner,uint256 collectionId,uint256 expires,string seed)"
                        ),
                        _ticket.winner,
                        _ticket.collectionId,
                        _ticket.expires,
                        keccak256(bytes(_ticket.seed))
                    )
                )
            );
    }

    // solhint-disable-next-line no-unused-vars
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
