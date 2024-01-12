// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

/*
 ____                   _           _         
|  _ \                 | |         | |        
| |_) | __ _ ___  ___  | |     __ _| |__  ___ 
|  _ < / _` / __|/ _ \ | |    / _` | '_ \/ __|
| |_) | (_| \__ \  __/ | |___| (_| | |_) \__ \
|____/ \__,_|___/\___| |______\__,_|_.__/|___/
                                              
*/

pragma solidity ^0.8.7;

/**
 * @title OnChainRandom
 * @author BaseLabs
 */
contract OnChainRandom {
    uint256 private _seed;
    /**
     * @notice _unsafeRandom is used to generate a random number by on-chain randomness.
     * Please note that on-chain random is potentially manipulated by miners,
     * so VRF is recommended for most security-sensitive scenarios.
     * @return randomly generated number.
     */
    function _unsafeRandom() internal returns (uint256) {
    unchecked {
        _seed++;
        return uint256(keccak256(abi.encodePacked(
                blockhash(block.number - 1),
                block.difficulty,
                block.timestamp,
                block.coinbase,
                _seed,
                tx.origin
            )));
    }
    }
}

/**
 * @title RandomPairs
 * @author BaseLabs
 */
contract RandomPairs is OnChainRandom {
    struct Uint256Pair {
        uint256 key;
        uint256 value;
    }

    function _getPairsValueSum(Uint256Pair[] memory pairs_) internal pure returns (uint256) {
        unchecked {
            uint256 totalSize = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                totalSize += pairs_[i].value;
            }
            return totalSize;
        }
    }

    /**
     * @notice _genRandKeyByPairsWithSize is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @param totalSize_ the sum probabilities.
     * @return the key.
     */
    function _genRandKeyByPairsWithSize(Uint256Pair[] memory pairs_, uint256 totalSize_) internal returns (uint256) {
        unchecked {
            if (pairs_.length == 1) {
                return pairs_[0].key;
            }
            uint256 entropy = _unsafeRandom() % totalSize_;
            uint256 step = 0;
            for (uint256 i = 0; i < pairs_.length; i++) {
                step += pairs_[i].value;
                if (entropy < step) {
                    return pairs_[i].key;
                }
            }
            revert("unreachable code");
        }
    }

    /**
     * @notice _genRandKeyByPairs is used to randomly generate a key
     * according to the probability configuration.
     * @param pairs_ the probability configuration.
     * @return the key.
     */
    function _genRandKeyByPairs(Uint256Pair[] memory pairs_) internal returns (uint256) {
        return _genRandKeyByPairsWithSize(pairs_, _getPairsValueSum(pairs_));
    }
}


/**
 * @title IExtendableERC1155
 * @author BaseLabs
 */
abstract contract IExtendableERC1155 is IERC1155 {
    /**
     * @dev Transfers `amount_` tokens of token type `id_` from `from_` to `to`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - `from_` must have a balance of tokens of type `id_` of at least `amount`.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawSafeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     * Emits a {TransferBatch} event.
     * Requirements:
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawSafeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Creates `amount_` tokens of token type `id_`, and assigns them to `to_`.
     * Emits a {TransferSingle} event.
     * Requirements:
     * - `to_` cannot be the zero address.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function rawMint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     * - If `to_` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function rawMintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external virtual;

    /**
     * @dev Destroys `amount_` tokens of token type `id_` from `from_`
     * Requirements:
     * - `from_` cannot be the zero address.
     * - `from_` must have at least `amount` tokens of token type `id`.
     */
    function rawBurn(address from_, uint256 id_, uint256 amount_) external virtual;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     * Requirements:
     * - `ids_` and `amounts_` must have the same length.
     */
    function rawBurnBatch(address from_, uint256[] memory ids_, uint256[] memory amounts_) external virtual;

    /**
     * @dev Approve `operator_` to operate on all of `owner_` tokens
     * Emits a {ApprovalForAll} event.
     */
    function rawSetApprovalForAll(address owner_, address operator_, bool approved_) external virtual;
}

/**
 * @title CheersUpEmojiAirdrop
 * @author BaseLabs
 */
contract CheersUpEmojiAirdrop is Ownable, RandomPairs {
    event CUPOrientedAirdrop(uint256 indexed cupTokenId_, address indexed address_, uint256 indexed emojiTokenId_);
    event Airdrop(address indexed address_, uint256 indexed tokenId_);
    IExtendableERC1155 private _basic;
    IERC721 private _cheersup;

    constructor(address basicAddress_, address cheersUpAddress_) {
        _basic = IExtendableERC1155(basicAddress_);
        _cheersup = IERC721(cheersUpAddress_);
    }

    /**
     * @notice airdropByNum is used to airdrop tokens to the given address.
     * @param accounts_ the address to airdrop
     * @param nums_ number of tokens to airdrop for each address
     * @param numPairs_ define the tokenId and the corresponding quantity of this airdrop
     */
    function airdropByNum(address[] calldata accounts_, uint256[] calldata nums_, Uint256Pair[] calldata numPairs_) external onlyOwner {
        require(accounts_.length == nums_.length, "accounts_ and nums_ must have the same length");
    unchecked {
        uint256 total = 0;
        for (uint256 i = 0; i < nums_.length; i++) {
            total += nums_[i];
        }
        uint256[] memory bucket = _generateBucket(total, numPairs_);
        uint256 cursor = 0;
        for (uint256 i = 0; i < accounts_.length; i++) {
            uint256 num = nums_[i];
            address account = accounts_[i];
            for (uint256 j = 0; j < num; j++) {
                _basic.rawMint(account, bucket[cursor], 1, "");
                emit Airdrop(account, bucket[cursor]);
                cursor++;
            }
        }
    }
    }

    /**
     * @notice airdropByProbability is used to airdrop tokens to the given address.
     * @param accounts_ the address to airdrop
     * @param nums_ number of tokens to airdrop for each address
     * @param probabilityPairs_ define the tokenId and the corresponding probability of this airdrop
     */
    function airdropByProbability(address[] calldata accounts_, uint256[] calldata nums_, Uint256Pair[] calldata probabilityPairs_) external onlyOwner {
        require(accounts_.length == nums_.length, "accounts_ and nums_ must have the same length");
    unchecked {
        uint256 totalSize = _getPairsValueSum(probabilityPairs_);
        for (uint256 i = 0; i < accounts_.length; i++) {
            uint256 num = nums_[i];
            address account = accounts_[i];
            for (uint256 j = 0; j < num; j++) {
                uint256 tokenId = _genRandKeyByPairsWithSize(probabilityPairs_, totalSize);
                _basic.rawMint(account, tokenId, 1, "");
                emit Airdrop(account, tokenId);
            }
        }
    }
    }

    /**
     * @notice airdropToCUPByNum is used to airdrop based on the CUP token id.
     * @param cupTokenIds_ cheers up token ids
     * @param nums_ number of tokens to airdrop for each cup token id
     * @param numPairs_ define the tokenId and the corresponding quantity of this airdrop
     */
    function airdropToCUPByNum(uint256[] calldata cupTokenIds_, uint256[] calldata nums_, Uint256Pair[] calldata numPairs_) external onlyOwner {
        require(cupTokenIds_.length == nums_.length, "cupTokenIds_ and nums_ must have the same length");
    unchecked {
        uint256 total = 0;
        for (uint256 i = 0; i < nums_.length; i++) {
            total += nums_[i];
        }
        uint256[] memory bucket = _generateBucket(total, numPairs_);
        uint256 cursor = 0;
        for (uint256 i = 0; i < cupTokenIds_.length; i++) {
            uint256 num = nums_[i];
            uint256 cupTokenId = cupTokenIds_[i];
            address tokenOwner = _cheersup.ownerOf(cupTokenId);
            for (uint256 j = 0; j < num; j++) {
                _basic.rawMint(tokenOwner, bucket[cursor], 1, "");
                emit CUPOrientedAirdrop(cupTokenId, tokenOwner, bucket[cursor]);
                cursor++;
            }
        }
    }
    }

    /**
     * @notice airdropToCUPByProbability is used to airdrop based on the CUP token id.
     * @param cupTokenIds_ cheers up token ids
     * @param nums_ number of tokens to airdrop for each cup token id
     * @param probabilityPairs_ define the tokenId and the corresponding probability of this airdrop
     */
    function airdropToCUPByProbability(uint256[] calldata cupTokenIds_, uint256[] calldata nums_, Uint256Pair[] calldata probabilityPairs_) external onlyOwner {
        require(cupTokenIds_.length == nums_.length, "cupTokenIds_ and nums_ must have the same length");
        uint256 totalSize = _getPairsValueSum(probabilityPairs_);
        for (uint256 i = 0; i < cupTokenIds_.length; i++) {
            uint256 cupTokenId = cupTokenIds_[i];
            uint256 num = nums_[i];
            address tokenOwner = _cheersup.ownerOf(cupTokenId);
            for (uint256 j = 0; j < num; j++) {
                uint256 tokenId = _genRandKeyByPairsWithSize(probabilityPairs_, totalSize);
                _basic.rawMint(tokenOwner, tokenId, 1, "");
                emit CUPOrientedAirdrop(cupTokenId, tokenOwner, tokenId);
            }
        }
    }

    /**
     * @notice generate a random array based on numPairs_
     * @param total_ total number of elements
     * @param numPairs_ array of Uint256Pair, it defines the number of each TokenId.
     * @return array of tokenId
     */
    function _generateBucket(uint256 total_, Uint256Pair[] memory numPairs_) internal returns (uint256[] memory) {
    unchecked {
        uint256[] memory bucket = new uint256[](total_);
        uint256 sum;
        uint256 cursor;
        for (uint256 i = 0; i < numPairs_.length; i++) {
            sum += numPairs_[i].value;
            for (uint256 j = 0; j < numPairs_[i].value; j++) {
                bucket[cursor] = numPairs_[i].key;
                cursor++;
            }
        }
        require(total_ == sum, "total_ must equal to sum");
        _shuffle(bucket);
        return bucket;
    }
    }

    /**
     * @notice _shuffle the array
     * @param items_ array to be shuffled
     */
    function _shuffle(uint256[] memory items_) internal {
    unchecked {
        for (uint256 i = items_.length - 1; i > 0; i--) {
            uint256 j = _unsafeRandom() % (i + 1);
            (items_[j], items_[i]) = (items_[i], items_[j]);
        }
    }
    }
}