// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./Strings.sol";
import "./RLPReader.sol";
import "./ERC721Base.sol";
import "./ReentrancyGuard.sol";
import "./KeepersMintWindowModifiers.sol";
import "./KeepersERC721Storage.sol";
import "./ConstantsLib.sol";
import "./PseudoRandomLib.sol";
import "./AllowlistStorage.sol";
import "./TransferRestrictionsInternal.sol";
import "./RoomNamingStorage.sol";
import "./Counters.sol";

abstract contract ERC721r is ERC721Base, KeepersMintWindowModifiers, ReentrancyGuard, TransferRestrictionsInternal {
    using Strings for uint256;
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for RLPReader.Iterator;
    using RLPReader for bytes;
    using Counters for Counters.Counter;

    uint256 internal constant INDEX_AVAILABLE = 0;

    /**
     * @notice Thrown if a pending commit already exists for the user
     */
    error PendingCommitAlreadyExists(uint128 numNFTs, uint128 commitBlock);
    /**
     * @notice Thrown if the specified number of tickets to mint is 0 or more than 10
     */
    error InvalidTicketAmount(uint256, uint256);
    /**
     * @notice Thrown if the specified number of tickets to mint is beyond the max allowed for the address
     */
    error MaxTicketsPerAddress(uint256, uint256, uint256);
    /**
     * @notice Thrown if the message does not have the right amount of ether
     */
    error InvalidEtherAmount(uint256);
    /**
     * @notice Thrown if the comittment is too new to be revealed
     */
    error CommitTooNew();
    /**
     * @notice Thrown if the comittment is too old to be revealed
     */
    error CommitExpired();
    /**
     * @notice Thrown if a user attempts to reveal a commit that does not exist
     */
    error NoPendingCommit();
    /**
     * @notice Thrown if user tried to mint but has not agreed to ToS
     */
    error MustAgreeToTermsAndConditions();
    /**
     * @notice Thrown if user tried to reveal with an invalid entropy block header
     */
    error InvalidBlockHeader();
    /**
     * @notice Thrown if either the provided number of tickets to mint is greater than 20000 max,
     * or if the provided number results in mining more than 20000 max
     */
    error MaxTicketSupplyReached();
    /**
     * @notice Thrown if the number of tickets to mint is greater than the
     * remaining supply for the current sales tier
     */
    error MaxTicketSupplyForSalesTierReached();
    /**
     * @notice Thrown if the user is not on the allowlist
     */
    error AddressNotOnAllowlist(address);

    event Commit(address indexed user, uint128 numNFTs);
    event Reveal(address indexed user, uint128 numNFTs, uint8 specialTicketCount);

    function currentSupply() public view virtual returns (uint256) {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        return ConstantsLib.MAX_TICKETS - l.numAvailableTokens;
    }

    /**
     * @notice Returns the total number of tickets that will be
     * minted by the end of the minting process
     */
    function totalCommits() public view virtual returns (uint256) {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        return l.numPendingCommitNFTs + currentSupply();
    }

    function maxSupply() public view virtual returns (uint256) {
        return ConstantsLib.MAX_TICKETS;
    }

    /*//////////////////////////////////////////////////////////////
                        COMMIT REVEAL MECHANISM
    //////////////////////////////////////////////////////////////*/

    /**
     * @param numNFTs The number of NFTs the user wishes to mint
     * @dev max of MAX_TICKETS commits total during the lifetime the mint
     * @dev only one commit permitted at a time for a given user
     */
    function commit(bool agreeToTermsOfService, uint128 numNFTs) public payable virtual whenMintWindowOpen {
        if (!agreeToTermsOfService) {
            revert MustAgreeToTermsAndConditions();
        }

        AllowlistStorage.Layout storage al = AllowlistStorage.layout();
        if (al.isAllowlistEnabled && !al.allowlist[msg.sender]) {
            revert AddressNotOnAllowlist(msg.sender);
        }

        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        // validate the user doesn't have a pending commit already
        if (l.pendingCommits[msg.sender].commitBlock != 0) {
            revert PendingCommitAlreadyExists(
                l.pendingCommits[msg.sender].numNFTs,
                l.pendingCommits[msg.sender].commitBlock
            );
        }

        if (numNFTs == 0) {
            revert InvalidTicketAmount(l.maxPerAddress, numNFTs);
        }

        uint256 totalInboundCommits = currentSupply() + numNFTs + l.numPendingCommitNFTs;
        uint256 maxMintsForSalesTier = l.maxMintsForSalesTier;
        if (maxMintsForSalesTier > 0 && totalInboundCommits > l.maxMintsForSalesTier) {
            revert MaxTicketSupplyForSalesTierReached();
        }

        if (totalInboundCommits > ConstantsLib.MAX_TICKETS) {
            revert MaxTicketSupplyReached();
        }

        if (numNFTs + l.mintCountPerAddress[msg.sender] > l.maxPerAddress) {
            revert MaxTicketsPerAddress(l.maxPerAddress, l.mintCountPerAddress[msg.sender], numNFTs);
        }

        uint256 mintPrice = al.isAllowlistEnabled ? ConstantsLib.ALLOWLSIT_MINT_PRICE : ConstantsLib.MINT_PRICE;

        // validate the user is sending the proper amount of eth
        if (msg.value != numNFTs * mintPrice) {
            revert InvalidEtherAmount(msg.value);
        }

        l.pendingCommits[msg.sender] = KeepersERC721Storage.MintCommit(numNFTs, uint128(block.number));
        l.numPendingCommitNFTs += numNFTs;

        emit Commit(msg.sender, numNFTs);
    }

    function pendingCommitByAddress(address addr) public view returns (KeepersERC721Storage.MintCommit memory) {
        return KeepersERC721Storage.layout().pendingCommits[addr];
    }

    function _validateCommitForReveal(
        KeepersERC721Storage.MintCommit memory pendingCommit,
        bytes calldata rlpEncodedEntropyBlockHeader
    ) internal view {
        // validate current block
        if (pendingCommit.commitBlock == 0) {
            revert NoPendingCommit();
        }

        uint256 entropyBlockNum = pendingCommit.commitBlock + ConstantsLib.MIN_COMMITMENT_BLOCKS;
        if (block.number <= entropyBlockNum) {
            revert CommitTooNew();
        }

        if (block.number > pendingCommit.commitBlock + ConstantsLib.MAX_COMMITMENT_BLOCKS) {
            revert CommitExpired();
        }

        // ensure the block header is valid
        bytes32 blockHashFromHeader = keccak256(rlpEncodedEntropyBlockHeader);
        bytes32 blockHashFromChain = blockhash(entropyBlockNum);

        if (blockHashFromHeader != blockHashFromChain) {
            revert InvalidBlockHeader();
        }
    }

    function reveal(bytes calldata rlpEncodedEntropyBlockHeader) external nonReentrant whenMintWindowOpen {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();

        KeepersERC721Storage.MintCommit memory pendingCommit = l.pendingCommits[msg.sender];
        _validateCommitForReveal(pendingCommit, rlpEncodedEntropyBlockHeader);

        // extract the randao (entropy) from the entropy block header
        // this is exposed as the "mixHash" which is the 14th value
        // (13 index) in the rlpEncoded header
        RLPReader.RLPItem[] memory ls = rlpEncodedEntropyBlockHeader.toRlpItem().toList();
        uint256 entropyBlockRandao = ls[13].toUint();

        uint256 personalizeRandSeed = uint256(keccak256(abi.encodePacked(entropyBlockRandao, msg.sender)));

        uint256 numNFTs = pendingCommit.numNFTs;

        // increase the mint count for the user
        l.mintCountPerAddress[msg.sender] += numNFTs;

        // decrease the number of pending commits
        l.numPendingCommitNFTs -= uint160(numNFTs);

        _reveal(personalizeRandSeed, numNFTs, msg.sender);
    }

    function _reveal(uint256 randNum, uint256 numNFTs, address ownerAddress) internal {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();

        // clear the pending commit and reclaim gas
        delete l.pendingCommits[ownerAddress];

        // mint the NFTs and roll for special-ness
        uint8 specialTicketCount;
        RoomNamingStorage.Layout storage r = RoomNamingStorage.layout();
        for (uint256 i; i < numNFTs; ) {
            randNum = PseudoRandomLib.deriveNewRandomNumber(randNum);

            uint256 tokenId = _mintRandomTokenId(ownerAddress, randNum);
            _maybeStoreAllowlistMintTimestamp(tokenId);

            if (
                randNum % ConstantsLib.SPECIAL_TICKET_MINT_ODDS == 0 &&
                r.specialTicketsCount.current() < ConstantsLib.SPECIAL_TICKETS_COUNT
            ) {
                ++specialTicketCount;
                // Then assign the token room naming rights
                r.specialTicketsCount.increment();
                r.tokenIdToRoomRights[tokenId] = uint8(r.specialTicketsCount.current());
            }

            unchecked {
                i++;
            }
        }

        emit Reveal(ownerAddress, uint128(numNFTs), specialTicketCount);
    }

    function numPendingCommitNFTs() external view returns (uint256) {
        return KeepersERC721Storage.layout().numPendingCommitNFTs;
    }

    function mintCountByAddress(address addr) external view returns (uint256) {
        return KeepersERC721Storage.layout().mintCountPerAddress[addr];
    }

    /*//////////////////////////////////////////////////////////////
                        TOKEN ID SELECTION
    //////////////////////////////////////////////////////////////*/

    function _mintRandomTokenId(address to, uint256 randomNum) internal virtual returns (uint256 tokenId) {
        require(to != address(0), "ERC721: mint to the zero address");

        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();

        uint16 updatedNumAvailableTokens = l.numAvailableTokens;

        // we choose from the first `updatedNumAvailableTokens` available tokens
        // because each mint the availableTokens array is shrunk by 1
        uint256 randomIndex = randomNum % updatedNumAvailableTokens;
        tokenId = getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);

        --updatedNumAvailableTokens;
        l.numAvailableTokens = updatedNumAvailableTokens;

        _mint(to, tokenId);

        return tokenId;
    }

    // Implements https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    function getAvailableTokenAtIndex(
        uint256 indexToUse,
        uint256 updatedNumAvailableTokens
    ) internal returns (uint256 result) {
        KeepersERC721Storage.Layout storage l = KeepersERC721Storage.layout();
        uint256 valAtIndex = l.availableTokens[indexToUse];
        if (valAtIndex == INDEX_AVAILABLE) {
            // This means the index itself is still an available token
            result = indexToUse;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = updatedNumAvailableTokens - 1;
        uint256 lastValInArray = l.availableTokens[lastIndex];
        if (indexToUse != lastIndex) {
            // Replace the value at indexToUse, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            if (lastValInArray == INDEX_AVAILABLE) {
                // This means the index itself is still an available token
                l.availableTokens[indexToUse] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                l.availableTokens[indexToUse] = lastValInArray;
            }
        }
        if (lastValInArray != INDEX_AVAILABLE) {
            // Gas refund courtsey of @dievardump
            delete l.availableTokens[lastIndex];
        }
    }
}
