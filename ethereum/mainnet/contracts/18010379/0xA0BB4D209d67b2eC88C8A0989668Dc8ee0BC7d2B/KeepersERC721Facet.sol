// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./ERC721r.sol";
import "./PseudoRandomLib.sol";
import "./OwnableInternal.sol";
import "./ERC2981.sol";
import "./ERC165Base.sol";
import "./KeepersERC721Metadata.sol";
import "./KeepersAvatarAssignmentStorage.sol";
import "./ERC721Metadata.sol";
import "./ERC721BaseInternal.sol";
import "./ERC721Enumerable.sol";
import "./MintOperatorModifiers.sol";
import "./KeepersERC721Storage.sol";
import "./AllowlistStorage.sol";

contract KeepersERC721Facet is
    ERC721r,
    KeepersERC721Metadata,
    ERC2981,
    OwnableInternal,
    ERC165Base,
    ERC721Enumerable,
    MintOperatorModifiers
{
    /*//////////////////////////////////////////////////////////////
                            STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct TokenInfo {
        uint256 id;
        uint256 status;
        bool isSpecial;
        uint256 config;
        string tokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event TermsAcknowledged(address user, string wheretoFindTerms);

    event AdminMint(uint256 indexed count);

    event RevealSkipped(address recipient);

    /*//////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Thrown if the provided token ID does not exist
     */
    error TokenDoesNotExist(uint256);

    error ZeroAddressReceiver();

    /*//////////////////////////////////////////////////////////////
                        Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @param _recipients a list of addresses acquired off chain of
     * who have pending commits that need to be revealed
     */
    function adminRevealPendingCommits(address[] calldata _recipients) external onlyOwnerOrMintOperator nonReentrant {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        uint256 randNum = PseudoRandomLib.getPseudoRandomNumber(0);

        uint256 numNFTsRevealed;
        uint256 recipientsLength = _recipients.length;
        for (uint256 i; i < recipientsLength; i++) {
            randNum = PseudoRandomLib.deriveNewRandomNumber(randNum);
            uint256 numNFTs = l.pendingCommits[_recipients[i]].numNFTs;

            if (numNFTs == 0) {
                emit RevealSkipped(_recipients[i]);
                continue;
            }

            _reveal(randNum, numNFTs, _recipients[i]);
            numNFTsRevealed += numNFTs;
        }

        // update the number of pending commits
        l.numPendingCommitNFTs -= uint160(numNFTsRevealed);
    }

    // Used by Keepers team to mint unminted tickets at end of the 72 hour minting period
    function adminMintTickets(uint256 _count) external nonReentrant onlyOwnerOrMintOperator whenMintWindowClosed {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        address recipient = l.vaultAddress;
        if (recipient == address(0)) {
            revert ZeroAddressReceiver();
        }

        if (l.numPendingCommitNFTs + currentSupply() + _count > ConstantsLib.MAX_TICKETS) {
            revert MaxTicketSupplyReached();
        }

        uint256 randNum = PseudoRandomLib.getPseudoRandomNumber(0);
        for (uint256 i; i < _count; ) {
            randNum = PseudoRandomLib.getPseudoRandomNumber(randNum);
            _mintRandomTokenId(recipient, randNum);
            unchecked {
                ++i;
            }
        }

        emit AdminMint(_count);
    }

    // Emit event when transferring to acknowledge terms
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721BaseInternal, ERC721Metadata) {
        super._beforeTokenTransfer(from, to, tokenId);

        _enforceAllowlistTransferRestriction(tokenId);

        emit TermsAcknowledged(to, ConstantsLib.WHERE_TO_FIND_TERMS);
    }

    /*//////////////////////////////////////////////////////////////
                                MISC
    //////////////////////////////////////////////////////////////*/
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    // NOTE - this is to satisfy the OperatorFilterInterface
    // but will not be accessable from the diamond proxy contract
    function owner() public view override returns (address) {
        return _owner();
    }

    function saleStartTimestamp() external view returns (uint256) {
        return KeepersERC721Storage.layout().saleStartTimestamp;
    }

    function saleCompleteTimestamp() external view returns (uint256) {
        return KeepersERC721Storage.layout().saleCompleteTimestamp;
    }

    function isMintingWindowOpen() external view returns (bool) {
        return _isMintingWindowOpen();
    }

    function minCommitmentBlocks() external pure returns (uint256) {
        return ConstantsLib.MIN_COMMITMENT_BLOCKS;
    }

    function maxCommitmentBlocks() external pure returns (uint256) {
        return ConstantsLib.MAX_COMMITMENT_BLOCKS;
    }

    function getTokensForWallet(address wallet) external view returns (uint256[] memory) {
        uint256 tokenCount = _balanceOf(wallet);
        uint256[] memory tokens = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; ) {
            tokens[i] = _tokenOfOwnerByIndex(wallet, i);
            unchecked {
                i++;
            }
        }

        return tokens;
    }

    function getTokenInfoForWallet(address wallet) external view returns (TokenInfo[] memory tokens) {
        uint256 tokenCount = _balanceOf(wallet);

        tokens = new TokenInfo[](tokenCount);

        for (uint256 i; i < tokenCount; ) {
            uint256 id = _tokenOfOwnerByIndex(wallet, i);

            tokens[i] = TokenInfo({
                id: id,
                status: KeepersAvatarAssignmentStorage.layout().tokenConvertedToAvatar[id],
                isSpecial: RoomNamingStorage.layout().tokenIdToRoomRights[id] != 0,
                config: KeepersAvatarAssignmentStorage.layout().configForToken[id],
                tokenURI: _tokenURI(id)
            });

            unchecked {
                i++;
            }
        }

        return tokens;
    }

    function bulkCheckPendingCommit(address[] calldata _addresses) external view returns (uint256[] memory) {
        uint256[] memory pendingCommits = new uint256[](_addresses.length);

        for (uint256 i; i < _addresses.length; i++) {
            pendingCommits[i] = KeepersERC721Storage.layout().pendingCommits[_addresses[i]].numNFTs;
        }

        return pendingCommits;
    }

    function mintPrice() external view returns (uint256) {
        AllowlistStorage.Layout storage l = AllowlistStorage.layout();
        return l.isAllowlistEnabled ? ConstantsLib.ALLOWLSIT_MINT_PRICE : ConstantsLib.MINT_PRICE;
    }
}
