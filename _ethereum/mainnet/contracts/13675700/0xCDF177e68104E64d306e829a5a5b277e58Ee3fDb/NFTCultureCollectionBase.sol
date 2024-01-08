// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./INFTCult_ForTheGallery.sol";
import "./INFTCForgeComponents_ForTheGallery.sol";

/**
 * @title NFT Culture Collection
 * @author @NiftyMike, NFT Culture
 * @dev An ERC 1155 implementation for gas efficient claiming of
 * airdrip pieces.
 */
abstract contract NFTCultureCollectionBase is
    ERC1155Supply,
    Ownable,
    ReentrancyGuard
{
    uint256 public constant EMBER_SUPPLY = 10**12;
    uint256 public constant NFT_CULT_TOKEN_COUNT = 3333;

    uint256 public constant OG_FOURD_PIECE_ID = 1;
    uint256 public constant OG_PAVEL_PIECE_ID = 2;
    uint256 public constant OG_CHISS_PIECE_ID = 3;
    uint256 public constant OG_ANONY_PIECE_ID = 4;

    string public name;
    uint256 public pricePerToken;
    bool public claimingActive;
    uint256 public emberPieceId;
    uint256[] public emberIds;
    uint256[] public pieceIds;

    INFTCult_ForTheGallery private _nftCult;
    INFTCForgeComponents_ForTheGallery private _nftCultForgeComponents;

    // For future extension
    mapping(uint256 => uint256) private _emberLookup;

    // Format: [64 bit claims consumed][64 bit claims yield][64 bit ember received][64 bit ember yield]
    mapping(uint256 => mapping(uint256 => uint256)) private _cache;
    uint256 private _cacheIndexer = 1;

    function _getForgeComponentYieldFromMapping(uint256 nftCultTokenId)
        internal
        view
        returns (uint256)
    {
        return
            _nftCultForgeComponents.getYieldFromMapping(
                _nftCult.tokenURI(nftCultTokenId)
            );
    }

    constructor(
        string memory __name,
        string memory __uri,
        uint256 __pricePerToken,
        address __nftCult,
        address __nftCultForgeComponents
    ) ERC1155(__uri) {
        name = __name;
        pricePerToken = __pricePerToken;

        emberPieceId = 0;
        emberIds.push(0);
        _emberLookup[0] = 1;

        _setNewDependencies(__nftCult, __nftCultForgeComponents);

        _mint(msg.sender, emberPieceId, EMBER_SUPPLY, '');
        _mint(msg.sender, OG_FOURD_PIECE_ID, NFT_CULT_TOKEN_COUNT, '');
        _mint(msg.sender, OG_PAVEL_PIECE_ID, NFT_CULT_TOKEN_COUNT, '');
        _mint(msg.sender, OG_CHISS_PIECE_ID, NFT_CULT_TOKEN_COUNT, '');
        _mint(msg.sender, OG_ANONY_PIECE_ID, NFT_CULT_TOKEN_COUNT, '');

        pieceIds = [
            OG_FOURD_PIECE_ID,
            OG_PAVEL_PIECE_ID,
            OG_CHISS_PIECE_ID,
            OG_ANONY_PIECE_ID
        ];
    }

    function _setNewDependencies(
        address __nftCult,
        address __nftCultForgeComponents
    ) internal {
        if (__nftCult != address(0)) {
            _nftCult = INFTCult_ForTheGallery(__nftCult);
        }

        if (__nftCultForgeComponents != address(0)) {
            _nftCultForgeComponents = INFTCForgeComponents_ForTheGallery(
                __nftCultForgeComponents
            );
        }
    }

    function getClaimsRemaining(uint256 nftCultTokenId)
        external
        view
        returns (uint256)
    {
        // Uninitialized
        if (_cache[_cacheIndexer][nftCultTokenId] == 0) {
            return _getForgeComponentYieldFromMapping(nftCultTokenId) >> 128;
        }

        // Initialized
        uint256 statsBitMap = _cache[_cacheIndexer][nftCultTokenId];
        return uint64(statsBitMap >> 128) - uint64(statsBitMap >> 192);
    }

    function getEmberRemaining(uint256 nftCultTokenId)
        external
        view
        returns (uint256)
    {
        // Uninitialized
        if (_cache[_cacheIndexer][nftCultTokenId] == 0) {
            return uint128(_getForgeComponentYieldFromMapping(nftCultTokenId));
        }

        // Initialized
        uint256 statsBitMap = _cache[_cacheIndexer][nftCultTokenId];
        return uint64(statsBitMap) - uint64(statsBitMap >> 64);
    }

    function isEmber(uint256 pieceId) external view returns (bool) {
        return _emberLookup[pieceId] == 1;
    }

    function setMintingState(
        bool __claimingActive,
        uint256 __pricePerToken,
        uint256 __emberPieceId,
        uint256 __cacheIndexer
    ) external onlyOwner {
        claimingActive = __claimingActive;

        if (__pricePerToken > 0) {
            // note: can't ever go back to zero.
            pricePerToken = __pricePerToken;
        }

        if (__emberPieceId > 0) {
            emberPieceId = __emberPieceId;
            emberIds.push(emberPieceId);
            _emberLookup[emberPieceId] = 1;
        }

        if (__cacheIndexer > 0) {
            _cacheIndexer = __cacheIndexer;
        }
    }

    function setNewURI(string memory newURI) external onlyOwner {
        _setURI(newURI);
    }

    function setNewDependencies(
        address __nftCult,
        address __nftCultForgeComponents
    ) external onlyOwner {
        _setNewDependencies(__nftCult, __nftCultForgeComponents);
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function addPieceToCollection(uint256 pieceId, uint256 tokenQuantity)
        external
        onlyOwner
    {
        require(balanceOf(msg.sender, pieceId) == 0, 'Cant add to collection');

        _mint(msg.sender, pieceId, tokenQuantity, '');

        pieceIds.push(pieceId);
    }

    function burnRemainingPieces(uint256 pieceId) external onlyOwner {
        uint256 balance = balanceOf(msg.sender, pieceId);

        _burn(msg.sender, pieceId, balance);
    }

    function claimPiecesInCollection(
        uint256 nftCultTokenId,
        uint256 pieceId,
        uint256 count
    ) external payable nonReentrant {
        require(claimingActive == true, 'Claiming disabled');
        require(exists(pieceId), 'Invalid piece to claim');
        require(
            _nftCult.ownerOf(nftCultTokenId) == msg.sender,
            'Cult token not owned'
        );

        uint256 statsBitMap = _cache[_cacheIndexer][nftCultTokenId];
        if (statsBitMap == 0) {
            // We havent seen this token before, so we must look up.
            statsBitMap = _getForgeComponentYieldFromMapping(nftCultTokenId);
        }
        require(statsBitMap > 0, 'Invalid forge component Id');

        uint64 claimYield = uint64(statsBitMap >> 128);
        uint64 claimsConsumed = uint64(statsBitMap >> 192);

        require(claimYield > 0, 'Cult token has no claims');
        require(claimsConsumed + count <= claimYield, 'No claims remaining');

        // Transfer the pieces.
        _safeTransferFrom(owner(), msg.sender, pieceId, count, '');

        // A fun bonus.
        uint64 emberYield = uint64(statsBitMap);
        uint64 embersReceived = uint64(statsBitMap >> 64);
        uint256 emberCount;
        if (emberYield > embersReceived) {
            emberCount = emberYield - embersReceived;
            _safeTransferFrom(
                owner(),
                msg.sender,
                emberPieceId,
                emberCount,
                ''
            );
        }

        _cache[_cacheIndexer][nftCultTokenId] =
            statsBitMap +
            (count << 192) +
            (emberCount << 64);
    }

    function batchClaimPiecesInCollection(
        uint256[] calldata nftCultTokens,
        uint256[] calldata pieceIdsToClaim,
        uint256[] calldata pieceCounts,
        bool useAlter
    ) external payable nonReentrant {
        require(claimingActive == true, 'Claiming disabled');
        require(nftCultTokens.length > 0, 'Must have claims');
        require(
            nftCultTokens.length == pieceIdsToClaim.length &&
                nftCultTokens.length == pieceCounts.length,
            'Bad inputs'
        );

        uint256 perTokenStatsBitMap;

        // value array since out of local var space.
        uint64[4] memory perToken;
        //uint256 perTokenPieceCount;
        //uint256 perTokenClaimYield;
        //uint256 perTokenClaimsConsumed;
        //uint256 perTokenAvailableEmbers;

        uint256 bonusEmber;

        uint256[] memory idsArr = new uint256[](nftCultTokens.length + 1);
        uint256[] memory countArr = new uint256[](nftCultTokens.length + 1);

        // Process each token one at a time. A token can be in the list multiple times if one of the claims is incomplete.
        for (uint256 i = 0; i < nftCultTokens.length; i++) {
            perToken[0] = uint64(pieceCounts[i]); // requested count

            require(exists(pieceIdsToClaim[i]), 'Invalid piece to claim');
            require(
                _nftCult.ownerOf(nftCultTokens[i]) == msg.sender,
                'Cult token not owned'
            );

            perTokenStatsBitMap = _cache[_cacheIndexer][nftCultTokens[i]];

            if (perTokenStatsBitMap == 0) {
                // We havent seen this token before, so we must look up.
                perTokenStatsBitMap = _getForgeComponentYieldFromMapping(
                    nftCultTokens[i]
                );
            }
            require(perTokenStatsBitMap > 0, 'Invalid forge component Id');

            perToken[1] = uint64(perTokenStatsBitMap >> 128); // yield
            perToken[2] = uint64(perTokenStatsBitMap >> 192); // consumed

            require(perToken[1] > 0, 'Cult token has no claims');
            require(
                perToken[2] + perToken[0] <= perToken[1],
                'No claims remaining'
            );

            if (pieceIdsToClaim[i] == emberPieceId) {
                require(useAlter, 'Use alter to claim ember.');
            }

            idsArr[i] = pieceIdsToClaim[i];
            countArr[i] = perToken[0];

            perToken[3] = uint64(_computeBonusEmber(perTokenStatsBitMap));

            bonusEmber += perToken[3];

            // update the token stats.
            _cache[_cacheIndexer][nftCultTokens[i]] =
                perTokenStatsBitMap +
                (uint256(perToken[0]) << 192) +
                (uint256(perToken[3]) << 64); // dont include alter ember here.
        }

        // use the last slot in the array for ember. this will be slightly inefficient if no ember claimed, but that should be the
        // less likely case.
        idsArr[nftCultTokens.length] = emberPieceId;
        countArr[nftCultTokens.length] = bonusEmber;

        // now do the transfers all as a batch.
        _safeBatchTransferFrom(owner(), msg.sender, idsArr, countArr, '');
    }

    function _computeBonusEmber(uint256 bitMap)
        internal
        pure
        returns (uint256)
    {
        uint256 perTokenEmberYield = uint64(bitMap);
        uint256 pertokenEmbersRecieved = uint64(bitMap >> 64);

        uint256 bonusEmber;
        if (perTokenEmberYield > pertokenEmbersRecieved) {
            bonusEmber = perTokenEmberYield - pertokenEmbersRecieved;
        }

        return bonusEmber;
    }
}
