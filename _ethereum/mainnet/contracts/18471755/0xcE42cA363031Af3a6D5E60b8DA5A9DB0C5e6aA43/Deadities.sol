// SPDX-License-Identifier: MIT
// Copyright 2023 Divergence Tech Ltd
pragma solidity ^0.8.19;

import "./MythicsV3.sol";
import "./SacrificedOddityMythics.sol";
import "./BaseTokenURI.sol";
import "./IERC721Metadata.sol";
import "./Strings.sol";

/**
 * @title Deadities
 * @notice Shadow NFTs that always follow Moonbirds Mythics as they are transferred. Only those Mythics that were minted
 * as a result of the "sacrifice" of an Oddity have an associated Deadity.
 * @dev As these tokens shadow the ownership of others, all transfer-related functionality is disabled.
 * @author Arran Schlosberg (@divergencearran)
 * @custom:reviewer David Huber (@cxkoda)
 */
contract Deadities is IERC721Metadata, IERC721TransferListener, BaseTokenURI {
    using Strings for uint256;

    /**
     * @notice Throw by functions that have been disabled. See contract-level @notice + @dev for rationale.
     */
    error FunctionDisabled();

    /**
     * @notice Thrown if a token doesn't exist.
     */
    error NonExistentToken(uint256 tokenId);

    /**
     * @notice Thrown by onTransfer() if called by any address other than the Mythics contract.
     */
    error OnlyMythicsContract(address caller);

    /**
     * @dev Guess.
     */
    IERC721 private immutable mythics;

    /**
     * @dev Number of bitmaps (encoding Mythic IDs) that have been processed by mint().
     */
    uint256 private _bitmapsMinted;

    constructor(IERC721 mythics_, address admin) BaseTokenURI("") {
        mythics = mythics_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(DEFAULT_STEERING_ROLE, msg.sender);
    }

    /**
     * @notice Mints the next batch of tokens.
     * @dev We rely entirely on the respective Mythics token for ownership so there is no storage bookkeeping, there is
     * only a Transfer(0, …) event emitted.
     * @param numBitmaps Mythic IDs for which a Deadity exists are stored in bitmaps of up to 256 IDs; specifies how
     * many bitmaps of IDs to process. Note that not all encode the same number of IDs.
     */
    function mint(uint256 numBitmaps) external {
        uint256 mapId = _bitmapsMinted;
        uint256 end = mapId + numBitmaps;
        IERC721 _mythics = mythics;

        unchecked {
            // This takes approximately 13M gas when the mythics.ownerOf() is stubbed out with a pure
            // function. It will be more in production because of the storage reads.
            for (; mapId < end; ++mapId) {
                uint256 offset = 0;
                for (uint256 map = SacrificedOddityMythics._bitmap(mapId); map > 0; map >>= 1) {
                    if ((map & uint256(1)) == 1) {
                        uint256 tokenId = mapId * 256 + offset;
                        emit IERC721.Transfer(address(0), _mythics.ownerOf(tokenId), tokenId);
                    }
                    ++offset;
                }
            }
        }

        _bitmapsMinted = end;
    }

    modifier tokenExists(uint256 tokenId) {
        if (!SacrificedOddityMythics._fromOddity(tokenId)) {
            revert NonExistentToken(tokenId);
        }
        _;
    }

    /**
     * @dev See mint() for rationale re naked emit.
     */
    function _transfer(address from, address to, uint256 tokenId) private {
        emit IERC721.Transfer(from, to, tokenId);
    }

    /**
     * @dev Hook called by the Mythics contract when token(s) are transferred, resulting in respective Transfer events
     * for those Mythics that were created due to the sacrifice of an Oddity.
     */
    function onTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) external {
        if (msg.sender != address(mythics)) {
            revert OnlyMythicsContract(msg.sender);
        }
        uint256 end = firstTokenId + batchSize;
        for (uint256 tokenId = firstTokenId; tokenId < end; ++tokenId) {
            if (SacrificedOddityMythics._fromOddity(tokenId)) {
                _transfer(from, to, tokenId);
            }
        }
    }

    /**
     * @dev Returns the token collection name.
     */
    function name() external pure returns (string memory) {
        return "Deadities";
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external pure returns (string memory) {
        return "DEAD";
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     */
    function ownerOf(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return mythics.ownerOf(tokenId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), tokenId.toString()));
    }

    /**
     * @notice Returns the total number of tokens.
     */
    function totalSupply() external pure returns (uint256) {
        return SacrificedOddityMythics.NUM_BITS_SET;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     * @dev Implementation is O(max(tokenId)) so is only suitable for off-chain indexing.
     */
    function balanceOf(address owner) external view returns (uint256) {
        IERC721 _mythics = mythics;
        uint256 balance;

        unchecked {
            for (uint256 mapId = 0; mapId < SacrificedOddityMythics.NUM_BITMAPS; ++mapId) {
                uint256 offset = 0;

                for (uint256 map = SacrificedOddityMythics._bitmap(mapId); map > 0; map >>= 1) {
                    if ((map & uint256(1)) == 1 && _mythics.ownerOf(mapId * 256 + offset) == owner) {
                        ++balance;
                    }

                    ++offset;
                }
            }
        }

        return balance;
    }

    /**
     * @notice Disabled but present to compile as IERC721.
     */
    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert FunctionDisabled();
    }

    /**
     * @notice Disabled but present to compile as IERC721.
     */
    function safeTransferFrom(address, address, uint256) external pure {
        revert FunctionDisabled();
    }

    /**
     * @notice Disabled but present to compile as IERC721.
     */
    function transferFrom(address, address, uint256) external pure {
        revert FunctionDisabled();
    }

    /**
     * @notice Disabled but present to compile as IERC721.
     */
    function approve(address, uint256) external pure {
        revert FunctionDisabled();
    }

    /**
     * @notice Disabled but present to compile as IERC721.
     */
    function setApprovalForAll(address, bool) external pure {
        revert FunctionDisabled();
    }

    /**
     * @notice Always returns 0;
     */
    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    /**
     * @notice Always returns false;
     */
    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerable, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId || AccessControlEnumerable.supportsInterface(interfaceId);
    }
}
