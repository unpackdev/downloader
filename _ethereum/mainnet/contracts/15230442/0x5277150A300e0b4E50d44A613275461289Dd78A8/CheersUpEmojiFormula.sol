// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";

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
 * @title CheersUpEmojiFormula
 * @author BaseLabs
 */
contract CheersUpEmojiFormula is Ownable, RandomPairs, ReentrancyGuard {
    event FormulaCreated(uint256 indexed formulaId);
    event Rerolled(address indexed account, uint256 indexed formulaId, uint256 indexed tokenId);
    struct Formula {
        uint256 startTime;
        uint256 endTime;
        Uint256Pair[] input;
        Uint256Pair[] output;
    }

    IExtendableERC1155 private _basic;
    mapping(uint256 => Formula) private _formulas;

    constructor(address basicAddress_) {
        _basic = IExtendableERC1155(basicAddress_);
    }

    /**
     * @notice use a formula to reroll,
     * it will generate a new token id according to the input and output of the formula, with some randomness
     * @param formulaId_ the id of the formula.
     */
    function reroll(uint256 formulaId_) external nonReentrant {
        (Formula memory formula, bool valid) = getFormula(formulaId_);
        require(valid, "formula is not valid now");
        for (uint256 i = 0; i < formula.input.length; i++) {
            _basic.rawBurn(msg.sender, formula.input[i].key, formula.input[i].value);
        }
        uint256 tokenId = _genRandKeyByPairs(formula.output);
        _basic.rawMint(msg.sender, tokenId, 1, "");
        emit Rerolled(msg.sender, formulaId_, tokenId);
    }

    /**
     * @notice create a new formula.
     * @param formulaId_ the id of the formula, when the id is already in used and the overwrite_ is true,
       the original formula will be overwritten.
     * @param formula_ the config of the formula.
     * @param overwrite_ whether to overwrite the existing formula.
     */
    function setFormula(uint256 formulaId_, Formula calldata formula_, bool overwrite_) external onlyOwner {
        if (!overwrite_) {
            require(_formulas[formulaId_].input.length == 0, "formula id already exists");
        }
        require(formula_.output.length > 0, "formula output is empty");
        require(formula_.input.length > 0, "formula input is empty");
        _formulas[formulaId_] = formula_;
        emit FormulaCreated(formulaId_);
    }

    /**
     * @notice get formula by id.
     * @param formulaId_ the id of the formula.
     * @return formula_ the config of the formula.
     * @return valid_ whether the formula is valid.
     */
    function getFormula(uint256 formulaId_) public view returns (Formula memory formula_, bool valid_) {
        formula_ = _formulas[formulaId_];
        valid_ = isFormulaValid(formula_);
    }

    /**
     * @notice check if the formula is valid.
     * @param formula_ the config of the formula.
     * @return valid_ whether the formula is valid.
     */
    function isFormulaValid(Formula memory formula_) public view returns (bool) {
        if (formula_.input.length == 0 || formula_.output.length == 0) {
            return false;
        }
        if (formula_.endTime > 0 && block.timestamp > formula_.endTime) {
            return false;
        }
        return formula_.startTime > 0 && block.timestamp > formula_.startTime;
    }
}
