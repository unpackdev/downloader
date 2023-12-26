// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IPBT.sol";
import "./ERC721ReadOnly.sol";
import "./ECDSA.sol";

error InvalidSignature();
error InvalidChipAddress();
error NoMintedTokenForChip();
error ArrayLengthMismatch();
error ChipAlreadyLinkedToMintedToken();
error UpdatingChipForUnsetChipMapping();
error NoMoreTokenIds();
error InvalidBlockNumber();
error BlockNumberTooOld();

error InvalidTokenIdRange();
error InvalidTokenIdForNonRandomSet();
error AlreadyAtMaxSupply();
error SeedingChipDataForExistingToken();

/**
 * Implementation of PBT where the tokenIds are split into two sets. The PBT's chip address determines which set it is in.
 * Set 1:
 *  - tokenId range: [0, RANDOM_TOKEN_ID_UPPER_BOUND)
 *  - tokenId pseudorandomly assigned onchain at mint time
 * Set 2:
 *  - tokenId range: [RANDOM_TOKEN_ID_UPPER_BOUND, ?)
 *  - tokenId assigned to chipAddress offchain (that mapping is still uploaded onchain)
 *
 * Example: suppose RANDOM_TOKEN_ID_UPPER_BOUND is 550.
 * If your PBT's chip is in the random set, it will have an id between 0 to 549, inclusive.
 * If your PBT's chip is in the nonrandom set, it will have an id >= 550.
 */
contract PBTTwoTiered is ERC721ReadOnly, IPBT {
    using ECDSA for bytes32;

    struct TokenData {
        uint256 tokenId;
        address chipAddress;
        bool set;
    }

    // Mapping from chipAddress to TokenData
    mapping(address => TokenData) _tokenDatas;

    // Data structure used for Fisher Yates shuffle for the random gen set
    uint256 private _numAvailableRemainingTokensInRandomGenSet;
    mapping(uint256 => uint256)
        internal _availableRemainingTokensInRandomGenSet;
    uint256 public immutable RANDOM_TOKEN_ID_UPPER_BOUND;

    // Data structure used to track non-random gen chip addresses
    // Mapping values are token ids (0 is an invalid token id for this set (falsy))
    mapping(address => uint256) public chipAddressesForNonRandomSet;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 randomTokenIdUpperBound
    ) ERC721ReadOnly(name_, symbol_) {
        _numAvailableRemainingTokensInRandomGenSet = randomTokenIdUpperBound;
        RANDOM_TOKEN_ID_UPPER_BOUND = randomTokenIdUpperBound;
    }

    function _seedChipAddresses(address[] memory chipAddresses) internal {
        for (uint256 i; i < chipAddresses.length; ++i) {
            address chipAddress = chipAddresses[i];
            _tokenDatas[chipAddress] = TokenData(0, chipAddress, false);
        }
    }

    function _seedChipToTokenMappingForNonRandomSet(
        address[] memory chipAddresses,
        uint256[] memory tokenIds,
        bool throwIfInvalid
    ) internal {
        uint256 tokenIdsLength = tokenIds.length;
        if (tokenIdsLength != chipAddresses.length) {
            revert ArrayLengthMismatch();
        }
        for (uint256 i; i < tokenIdsLength; ++i) {
            address chipAddress = chipAddresses[i];
            uint256 tokenId = tokenIds[i];
            if (throwIfInvalid) {
                if (_exists(tokenId)) revert SeedingChipDataForExistingToken();
                if (tokenId < RANDOM_TOKEN_ID_UPPER_BOUND || tokenId == 0)
                    revert InvalidTokenIdForNonRandomSet();
            }
            chipAddressesForNonRandomSet[chipAddress] = tokenId;
        }
    }

    function _updateChips(
        address[] calldata chipAddressesOld,
        address[] calldata chipAddressesNew
    ) internal {
        if (chipAddressesOld.length != chipAddressesNew.length) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i = 0; i < chipAddressesOld.length; i++) {
            address oldChipAddress = chipAddressesOld[i];
            if (!_tokenDatas[oldChipAddress].set) {
                revert UpdatingChipForUnsetChipMapping();
            }
            address newChipAddress = chipAddressesNew[i];
            uint256 tokenId = _tokenDatas[oldChipAddress].tokenId;
            _tokenDatas[newChipAddress] = TokenData(
                tokenId,
                newChipAddress,
                true
            );
            emit PBTChipRemapping(tokenId, oldChipAddress, newChipAddress);
            delete _tokenDatas[oldChipAddress];
        }
    }

    function tokenIdFor(
        address chipAddress
    ) external view override returns (uint256) {
        if (!_tokenDatas[chipAddress].set) {
            revert NoMintedTokenForChip();
        }
        return _tokenDatas[chipAddress].tokenId;
    }

    // Returns true if the signer of the signature of the payload is the chip for the token id
    function isChipSignatureForToken(
        uint256 tokenId,
        bytes memory payload,
        bytes memory signature
    ) public view override returns (bool) {
        if (!_exists(tokenId)) {
            revert NoMintedTokenForChip();
        }
        bytes32 signedHash = keccak256(payload).toEthSignedMessageHash();
        address chipAddr = signedHash.recover(signature);
        return
            _tokenDatas[chipAddr].set &&
            _tokenDatas[chipAddr].tokenId == tokenId;
    }

    // Parameters:
    //    to: the address of the new owner
    //    signatureFromChip: signature(receivingAddress + recentBlockhash), signed by an approved chip
    //
    // Contract should check that (1) recentBlockhash is a recent blockhash, (2) receivingAddress === to, and (3) the signing chip is allowlisted.
    function _mintTokenWithChip(
        bytes memory signatureFromChip,
        uint256 blockNumberUsedInSig
    ) internal returns (uint256) {
        address chipAddr = _getChipAddrForChipSignature(
            signatureFromChip,
            blockNumberUsedInSig
        );

        if (_tokenDatas[chipAddr].set) {
            revert ChipAlreadyLinkedToMintedToken();
        } else if (_tokenDatas[chipAddr].chipAddress != chipAddr) {
            revert InvalidChipAddress();
        }

        uint256 tokenId = chipAddressesForNonRandomSet[chipAddr];
        if (tokenId == 0) {
            tokenId = _useRandomAvailableTokenId();
        }

        _mint(_msgSender(), tokenId);

        _tokenDatas[chipAddr] = TokenData(tokenId, chipAddr, true);

        emit PBTMint(tokenId, chipAddr);

        return tokenId;
    }

    // Generates a pseudorandom number between [0,RANDOM_TOKEN_ID_UPPER_BOUND) that has not yet been generated before, in O(1) time.
    //
    // Uses Durstenfeld's version of the Yates Shuffle https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    // with a twist to avoid having to manually spend gas to preset an array's values to be values 0...n.
    // It does this by interpreting zero-values for an index X as meaning that index X itself is an available value
    // that is returnable.
    //
    // How it works:
    //  - zero-initialize a mapping (_availableRemainingTokensInRandomGenSet) and track its length (_numAvailableRemainingTokensInRandomGenSet). functionally similar to an array with dynamic sizing
    //    - this mapping will track all remaining valid values that haven't been generated yet, through a combination of its indices and values
    //      - if _availableRemainingTokensInRandomGenSet[x] == 0, that means x has not been generated yet
    //      - if _availableRemainingTokensInRandomGenSet[x] != 0, that means _availableRemainingTokensInRandomGenSet[x] has not been generated yet
    //  - when prompted for a random number between [0,RANDOM_TOKEN_ID_UPPER_BOUND) that hasn't already been used:
    //    - generate a random index randIndex between [0,_numAvailableRemainingTokensInRandomGenSet)
    //    - examine the value at _availableRemainingTokensInRandomGenSet[randIndex]
    //        - if the value is zero, it means randIndex has not been used, so we can return randIndex
    //        - if the value is non-zero, it means the value has not been used, so we can return _availableRemainingTokensInRandomGenSet[randIndex]
    //    - update the _availableRemainingTokensInRandomGenSet mapping state
    //        - set _availableRemainingTokensInRandomGenSet[randIndex] to either the index or the value of the last entry in the mapping (depends on the last entry's state)
    //        - decrement _numAvailableRemainingTokensInRandomGenSet to mimic the shrinking of an array
    function _useRandomAvailableTokenId() internal returns (uint256) {
        uint256 numAvailableRemainingTokens = _numAvailableRemainingTokensInRandomGenSet;
        if (numAvailableRemainingTokens == 0) {
            revert NoMoreTokenIds();
        }

        uint256 randomNum = _getRandomNum(numAvailableRemainingTokens);
        uint256 randomIndex = randomNum % numAvailableRemainingTokens;
        uint256 valAtIndex = _availableRemainingTokensInRandomGenSet[
            randomIndex
        ];

        uint256 result;
        if (valAtIndex == 0) {
            // This means the index itself is still an available token
            result = randomIndex;
        } else {
            // This means the index itself is not an available token, but the val at that index is.
            result = valAtIndex;
        }

        uint256 lastIndex = numAvailableRemainingTokens - 1;
        if (randomIndex != lastIndex) {
            // Replace the value at randomIndex, now that it's been used.
            // Replace it with the data from the last index in the array, since we are going to decrease the array size afterwards.
            uint256 lastValInArray = _availableRemainingTokensInRandomGenSet[
                lastIndex
            ];
            if (lastValInArray == 0) {
                // This means the index itself is still an available token
                _availableRemainingTokensInRandomGenSet[
                    randomIndex
                ] = lastIndex;
            } else {
                // This means the index itself is not an available token, but the val at that index is.
                _availableRemainingTokensInRandomGenSet[
                    randomIndex
                ] = lastValInArray;
                delete _availableRemainingTokensInRandomGenSet[lastIndex];
            }
        }

        _numAvailableRemainingTokensInRandomGenSet--;

        return result;
    }

    // Devs can swap this out for something less gameable like chainlink if it makes sense for their use case.
    function _getRandomNum(
        uint256 numAvailableRemainingTokens
    ) internal view virtual returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encode(
                        _msgSender(),
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        block.prevrandao,
                        blockhash(block.number - 1),
                        address(this),
                        numAvailableRemainingTokens
                    )
                )
            );
    }

    function transferTokenWithChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) public override {
        transferTokenWithChip(signatureFromChip, blockNumberUsedInSig, false);
    }

    function transferTokenWithChip(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig,
        bool useSafeTransferFrom
    ) public override {
        TokenData memory tokenData = _getTokenDataForChipSignature(
            signatureFromChip,
            blockNumberUsedInSig
        );
        uint256 tokenId = tokenData.tokenId;
        if (useSafeTransferFrom) {
            _safeTransfer(ownerOf(tokenId), _msgSender(), tokenId, "");
        } else {
            _transfer(ownerOf(tokenId), _msgSender(), tokenId);
        }
    }

    function _getTokenDataForChipSignature(
        bytes calldata signatureFromChip,
        uint256 blockNumberUsedInSig
    ) internal view returns (TokenData memory) {
        address chipAddr = _getChipAddrForChipSignature(
            signatureFromChip,
            blockNumberUsedInSig
        );
        TokenData memory tokenData = _tokenDatas[chipAddr];
        if (tokenData.set) {
            return tokenData;
        }
        revert InvalidSignature();
    }

    function _getChipAddrForChipSignature(
        bytes memory signatureFromChip,
        uint256 blockNumberUsedInSig
    ) internal view returns (address) {
        // The blockNumberUsedInSig must be in a previous block because the blockhash of the current
        // block does not exist yet.
        if (block.number <= blockNumberUsedInSig) {
            revert InvalidBlockNumber();
        }

        if (block.number - blockNumberUsedInSig > getMaxBlockDelay()) {
            revert BlockNumberTooOld();
        }

        bytes32 blockHash = blockhash(blockNumberUsedInSig);
        bytes32 signedHash = keccak256(
            abi.encodePacked(_msgSender(), blockHash)
        ).toEthSignedMessageHash();
        return signedHash.recover(signatureFromChip);
    }

    function getMaxBlockDelay() public pure virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IPBT).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
