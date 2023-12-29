// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./Counters.sol";
import "./INF3CommunityCard.sol";
import "./ERC1155URIStorageUpgradeable.sol";

/// @title NF3 Community Cards
/// @dev This is the NFT contract for all the type of community cards offered

contract NF3CommunityCard is
    INF3CommunityCard,
    Initializable,
    ERC1155URIStorageUpgradeable,
    OwnableUpgradeable,
    ERC2981Upgradeable
{
    /// -----------------------------------------------------------------------
    /// Libaray Usage
    /// -----------------------------------------------------------------------

    using Counters for Counters.Counter;

    /// -----------------------------------------------------------------------
    /// Storage Variables
    /// -----------------------------------------------------------------------

    /// @dev mapping from batchId to it's corrosponding tokenIds
    mapping(uint => TokenIdsForBatch) public tokenIdsForBatch;

    /// @dev mapping from batchId to it's minting timeperiod
    /// NOTE : If timeperiod is 0 that means there is no deadline to mint
    mapping(uint => uint) public timePeriodForBatch;

    /// @dev mapping from batchId to it's whitelist addresses merkleRoot
    mapping(uint => bytes32) public whitelistForBatch;

    /// @dev mapping from batchId to addresses that already minted
    mapping(uint => mapping(address => bool)) public mintedInBatch;

    /// @dev current batchId
    Counters.Counter batchId;

    /// @dev current tokenId for new batch
    Counters.Counter currentTokenIdsUsed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize
    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        __ERC1155URIStorageUpgradeable_init(_name, _symbol);
        __Ownable_init();
        __ERC2981_init();

        batchId.increment();
        currentTokenIdsUsed.increment();
    }

    /// @notice Inherit from {INF3CommunityCard.sol}
    function mint(uint _batchId, bytes32[] calldata _proof) external override {
        bytes32 whitelistRoot = whitelistForBatch[_batchId];

        uint256[] memory validTokenIds = _getTokenIds(_batchId);

        uint timePeriodOfBatch = timePeriodForBatch[_batchId];

        // check of batch id exist
        _batchExist(whitelistRoot, validTokenIds);

        // check if mint is ongoing
        _mintOngoing(timePeriodOfBatch);

        // check if merkle proof is valid and if use has already minted
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender));
        bool isWhitelisted = verifyMerkleProof(whitelistRoot, _proof, _leaf);
        if (!isWhitelisted || mintedInBatch[_batchId][msg.sender]) {
            revert("NF3 community card : Not eligbile to mint");
        }

        // get 1 random number in the given range of batch size and mint 1 token id out of the thing
        uint tokenIdIndex = _getRandomTokenIdForBatch(validTokenIds.length);
        _mint(msg.sender, validTokenIds[tokenIdIndex], 1, "");

        // mark the user as already minted
        mintedInBatch[_batchId][msg.sender] = true;

        emit Minted(_batchId, validTokenIds[tokenIdIndex], msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Upgradeable.supportsInterface(interfaceId);
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from {INF3CommunityCard.sol}
    function addNewBatch(
        uint sizeOfBatch,
        bytes32 batchWhitelistRoot,
        uint timePeriodOfBatch
    ) external override onlyOwner {
        if (sizeOfBatch == 0 || batchWhitelistRoot == bytes32(0)) {
            revert("NF3 community card : Invalid batch data");
        }

        uint currentBatchId = batchId.current();

        // if timePeriodOfBatch > 0 then allow minting in the give time only
        if (timePeriodOfBatch > 0)
            timePeriodForBatch[currentBatchId] = timePeriodOfBatch;

        // set whitelist merkle tree root for this batch
        whitelistForBatch[currentBatchId] = batchWhitelistRoot;

        // set tokenIds in this batch
        uint256 starting = currentTokenIdsUsed.current();
        TokenIdsForBatch memory _tokenIdsForBatch = TokenIdsForBatch({
            startingTokenId: uint128(starting),
            endingTokenId: uint128(starting + sizeOfBatch - 1)
        });
        tokenIdsForBatch[currentBatchId] = _tokenIdsForBatch;

        // update tokenIds used
        currentTokenIdsUsed.incrementBy(sizeOfBatch);

        // update batch id
        batchId.increment();

        emit BatchAdded(currentBatchId, _tokenIdsForBatch, batchWhitelistRoot);
    }

    /// @notice Inherit from {INF3CommunityCard.sol}
    function updateBatch(
        uint _batchId,
        bytes32 _batchWhitelistRoot,
        uint _timePeriodOfBatch
    ) external override onlyOwner {
        bytes32 whitelistRoot = whitelistForBatch[_batchId];
        uint256[] memory validTokenIds = _getTokenIds(_batchId);

        uint timePeriodOfBatch = timePeriodForBatch[_batchId];

        // check of batch id exist
        _batchExist(whitelistRoot, validTokenIds);

        // check if mint is ongoing
        _mintOngoing(timePeriodOfBatch);

        if (_batchWhitelistRoot == bytes32(0)) {
            revert("NF3 community card : Invalid batch data");
        }

        // set new whitelist root
        whitelistForBatch[_batchId] = _batchWhitelistRoot;

        if (timePeriodOfBatch > 0)
            timePeriodForBatch[_batchId] = timePeriodOfBatch;

        // set new timePeriod
        timePeriodForBatch[_batchId] = _timePeriodOfBatch;

        emit BatchUpdated(_batchId, _batchWhitelistRoot, _timePeriodOfBatch);
    }

    /// @notice Inherit from {INF3CommunityCard.sol}
    function setBaseURI(string memory baseURI_) external override onlyOwner {
        emit BaseURISet(_baseURI, baseURI_);
        _setBaseURI(baseURI_);
    }

    /// @notice Inherit from {INF3CommunityCard.sol}
    function setDefaultRoyalty(
        address receiver,
        uint16 feeNumerator
    ) external override onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit RoyaltySet(feeNumerator, receiver, type(uint256).max);
    }

    /// @notice Inherit from {INF3CommunityCard.sol}
    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external override onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);

        emit RoyaltySet(feeNumerator, receiver, tokenId);
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Get a sudo random number from 0 to batch size
    /// @param batchSize Size of the batch used as upper bound of the random value
    function _getRandomTokenIdForBatch(
        uint batchSize
    ) internal view returns (uint256) {
        uint256 seed = batchSize;
        uint256 randomNumber = (uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.number,
                    block.timestamp,
                    seed
                )
            )
        ) % batchSize);

        return randomNumber;
    }

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Common function for checking if a batch's mint is ongoing
    /// @param _timePeriodOfBatch Timestamp when minting ends
    function _mintOngoing(uint _timePeriodOfBatch) internal view {
        if (_timePeriodOfBatch > 0 && _timePeriodOfBatch < block.timestamp) {
            revert("NF3 community card : Mint period is over");
        }
    }

    /// @dev Common function for checking if batch exist
    /// @param whitelistRoot Merkle root of the whitelsited addresses
    /// @param validTokenIds TokenIds in that batch
    function _batchExist(
        bytes32 whitelistRoot,
        uint[] memory validTokenIds
    ) internal pure {
        if (whitelistRoot == bytes32(0) || validTokenIds.length == 0) {
            revert("NF3 community card : Invalid batch id");
        }
    }

    function _getTokenIds(
        uint256 _batchId
    ) internal view returns (uint256[] memory) {
        TokenIdsForBatch memory _tokenIdsForBatch = tokenIdsForBatch[_batchId];
        uint256[] memory validTokenIds = new uint256[](
            (_tokenIdsForBatch.endingTokenId -
                _tokenIdsForBatch.startingTokenId) + 1
        );

        for (
            uint i = _tokenIdsForBatch.startingTokenId;
            i <= _tokenIdsForBatch.endingTokenId;

        ) {
            validTokenIds[
                i - _tokenIdsForBatch.startingTokenId
            ] = _tokenIdsForBatch.endingTokenId;

            unchecked {
                ++i;
            }
        }

        return validTokenIds;
    }
}
