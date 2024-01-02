// SPDX-License-Identifier: MIT

// Website: nimbl.tv
// X/Twitter: x.com/nimbltv
// Official Telegram: t.me/nimbltv
// Whitepaper: whitepaper.nimbl.tv


// File: token/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity ^0.8.20;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: @openzeppelin/contracts/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.20;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the Merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates Merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     *@dev The multiproof provided is not valid.
     */
    error MerkleProofInvalidMultiproof();

    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all Merkle trees admit multiproofs. See {processMultiProof} for details.
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the Merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        if (leavesLen + proofLen != totalHashes + 1) {
            revert MerkleProofInvalidMultiproof();
        }

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            if (proofPos != proofLen) {
                revert MerkleProofInvalidMultiproof();
            }
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Sorts the pair (a, b) and hashes the result.
     */
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    /**
     * @dev Implementation of keccak256(abi.encode(a, b)) that doesn't allocate or expand memory.
     */
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File: token/contracts/extensions/ExtensionMerkleWhiteList.sol


pragma solidity ^0.8.20;


abstract contract ExtensionMerkleWhiteList {
    mapping(bytes32 => address) internal _rootHolder;

    error RootAlreadyUsed();

    function _setRoot(bytes32 root, address holder) internal {
        if (_rootHolder[root] != address(0)) {
            revert RootAlreadyUsed();
        }
        _rootHolder[root] = holder;
    }

    function getLeaf(address account, uint256 amount) public pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
    }

    function _verify(
        bytes32[] memory proof,
        address account,
        uint256 amount,
        bytes32 root
    ) internal pure returns (bool, bytes32) {
        bytes32 leaf = getLeaf(account, amount);

        return (MerkleProof.verify(proof, root, leaf), leaf);
    }
}
// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: token/contracts/interfaces/INimblToken.sol


pragma solidity ^0.8.20;


interface INimblToken {
    struct TimetableTax {
        uint256 timestamp;
        uint16 taxBuy;
        uint16 taxSell;
    }

    struct MonthlyUnlock {
        string month;
        uint256 amount;
    }

    event UpdateExcludeFromFees(address indexed account, bool isExcluded);
    event Claim(address account, uint256 amount);

    error TradingClose();
    error ErrorVerify();
    error AlreadyClaimed();
    error ErrorRoot();
    error WrongHolder();

    function setExcludeFromFees(address account, bool excluded) external;
    
    function setPool(address account) external;

    function unlockFundsMonthly() external;
    
    function setTradingStatus(bool status) external;

    function openTrading() external;

    function claim(bytes32[] memory proof, uint256 amount, bytes32 root) external;

    function setRoot(bytes32 root, address holder) external;

    function getTaxesForDEX() external view returns (uint16 taxBuy, uint16 taxSell);

    function getV2PoolAddr() external view returns (address v2PoolAddr);

    function getVaultAddr() external view returns (address vaultAddr);

    function getTradingStatus() external view returns (bool);

    function isExcludedFromFee(address account) external view returns (bool status);

    function getUseProof(bytes32 root, bytes32 leaf) external view returns (bool status);

    function getTimetableTax() external view returns (TimetableTax[] memory _timetableTax);

    function verify(
        bytes32[] memory proof,
        address account,
        uint256 amount,
        bytes32 root
    ) external pure returns (bool status);
}
// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// File: token/contracts/NimblToken.sol


pragma solidity ^0.8.20;



library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}


/**
 * @notice
 * The NimblToken contract is a Solidity smart contract that
 *  represents a token called "Nimbl.tv" with the symbol "$NIMBL".
 *  It extends the ERC20 contract and implements the INimblToken
 *  interface. The contract includes functionality for managing
 *  fees, trading status.
 *  It also includes functions for claiming tokens based on
 *  a Merkle proof and setting various contract parameters.
 */

contract NimblToken is INimblToken, ERC20, Ownable, ExtensionMerkleWhiteList {

    using SafeMath for uint256;
    address internal _v2PoolAddr;
    address internal _vaultAddr;
    address internal _toPublicRound;
    address payable internal _taxWallet;
    address internal _toDEX;
    address internal _toCEX;

    uint256 public _taxSwapThreshold= 76000 * 10**decimals();
    uint256 public _maxTaxSwap= 760000 * 10**decimals();
    
    IUniswapV2Router02 internal _uniswapV2Router;

    bool internal _tradingOpen;
    bool internal _tradingStarted;

    mapping(address => bool) internal _isExcludedFromFee;
    mapping(bytes32 => mapping(bytes32 => bool)) internal _useProof; // root=> leaf => status

    TimetableTax[] internal _timetableTax;
    MonthlyUnlock[] internal _monthlyUnlock;
    uint256 internal _lastUnlockExecutionTime;
    uint256 internal _unlockExecutionCount;
    bool private inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor(
        address payable taxWallet,
        address vaultAddr,
        uint256 totalSupply,
        address toCEX,
        address toDEX,
        address toPublicRound
    ) payable ERC20("Nimbl.tv", "$NIMBL") Ownable(msg.sender) {
        _timetableTax.push(TimetableTax(0, 100, 100));
        _vaultAddr = vaultAddr;
        _toPublicRound = toPublicRound;
        _taxWallet = taxWallet;
        _toDEX = toDEX;
        _toCEX = toCEX;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_vaultAddr] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _tradingOpen = false;
        _tradingStarted = false;

        _mint(msg.sender, totalSupply * 10**decimals());

        uint256 hundredK = 100000;
        
        // Monthly unlock
        addMonthlyUnlock("_firstMonth", 500 * hundredK * 10**decimals());
        addMonthlyUnlock("_secondMonth", 372 * hundredK * 10**decimals());
        addMonthlyUnlock("_third", 412 * hundredK * 10**decimals());
        addMonthlyUnlock("_fouth", 296 * hundredK * 10**decimals());
        addMonthlyUnlock("_fifth", 296 * hundredK * 10**decimals());
        addMonthlyUnlock("_sixth", 476 * hundredK * 10**decimals());
        addMonthlyUnlock("_seventh", 324 * hundredK * 10**decimals());
        addMonthlyUnlock("_eight", 64 * hundredK * 10**decimals());
        addMonthlyUnlock("_ninth", 244 * hundredK * 10**decimals());
        addMonthlyUnlock("_tenth", 329 * hundredK * 10**decimals());
        addMonthlyUnlock("_eleventh", 64 * hundredK * 10**decimals());
        addMonthlyUnlock("_twelfth", 244 * hundredK * 10**decimals());
        addMonthlyUnlock("_thirteenth", 38566667 * 10**decimals());
        addMonthlyUnlock("_fourteenth", 12066666 * 10**decimals());
        addMonthlyUnlock("_fifteenth", 30066666 * 10**decimals());
        addMonthlyUnlock("_sixteenth", 38566667 * 10**decimals());
        addMonthlyUnlock("_seventeenth", 12066667 * 10**decimals());
        addMonthlyUnlock("_eighteenth", 30066667 * 10**decimals());
        addMonthlyUnlock("_nineteenth", 38566666 * 10**decimals());
        addMonthlyUnlock("_twentieth", 12066667 * 10**decimals());
        addMonthlyUnlock("_twentyfirst", 30066666 * 10**decimals());
        addMonthlyUnlock("_twentysecond", 38066667 * 10**decimals());
        addMonthlyUnlock("_twentythird", 12066667 * 10**decimals());
        addMonthlyUnlock("_twentyfourth", 15666667 * 10**decimals());
        addMonthlyUnlock("_twentyfifth", 26666667 * 10**decimals());
        addMonthlyUnlock("_twentysixth", 5666666 * 10**decimals());
        addMonthlyUnlock("_twentyseventh", 5666667 * 10**decimals());
        addMonthlyUnlock("_twentyeighth", 26666667 * 10**decimals());
        addMonthlyUnlock("_twentyninth", 5666667 * 10**decimals());
        addMonthlyUnlock("_thirtieth", 5666666 * 10**decimals());
        addMonthlyUnlock("_thirtyfirst", 25666667 * 10**decimals());
        addMonthlyUnlock("_thirtysecond", 5666667 * 10**decimals());
        addMonthlyUnlock("_thirtythird", 5666667 * 10**decimals());
        addMonthlyUnlock("_thirtyfourth", 5666666 * 10**decimals());
        addMonthlyUnlock("_thirtyfifth", 5666667 * 10**decimals());
        addMonthlyUnlock("_thirtysixth", 5666666 * 10**decimals());
        
        uint256 amountToUnlock = _monthlyUnlock[0].amount;
        super._transfer(msg.sender, _vaultAddr, amountToUnlock);
        _lastUnlockExecutionTime = block.timestamp;
        _unlockExecutionCount = 1;

        super._transfer(_vaultAddr, _toPublicRound, 300*hundredK * 10**decimals());
        super._transfer(_vaultAddr, toCEX, 80*hundredK * 10**decimals());
        super._transfer(_vaultAddr, toDEX, 120*hundredK * 10**decimals());
        

        // Launchpads
        uint256 _trustfiAmount = 859808 * 10**decimals();
        uint256 _nftbAmount = 279928 * 10**decimals();
        uint256 _kommunitasAmount = 6545455 * 10**decimals();
        uint256 _sporesAmount = 7272728 * 10**decimals();
        uint256 _maticAmount = 4328728 * 10**decimals();
        uint256 _roseonAmount = 125237 * 10**decimals();
        address _trustfi = 0xC0794F070908ccc2292C1faeD38eCC99BE901432;
        address _nftb = 0x5955b89C4f342161905C5Fc5a0425E8Bced06996;
        address _kommunitas = 0xDA5b4BFde0b6B4Fb21Be105F298069E9070953FB;
        address _spores = 0x938E833e313eEbe428eD069f375A379d1a07D5c2;
        address _matic = 0x18EFBc4AcDFbBE121f1D610E8e3e6924C29F64a7;
        address _roseon = 0xcBEBcCCF0B846C686D68c4D9EDA95fb17a7eedaE;

        super._transfer(_toPublicRound, _trustfi, _trustfiAmount);
        super._transfer(_toPublicRound, _nftb, _nftbAmount);
        super._transfer(_toPublicRound, _kommunitas, _kommunitasAmount);
        super._transfer(_toPublicRound, _spores, _sporesAmount);
        super._transfer(_toPublicRound, _matic, _maticAmount);
        super._transfer(_toPublicRound, _roseon, _roseonAmount);

    }
    
    function addMonthlyUnlock(string memory _month, uint256 _amount) internal {
        MonthlyUnlock memory newMonthlyUnlock = MonthlyUnlock(_month, _amount);
        _monthlyUnlock.push(newMonthlyUnlock);
    }

    /**
     * The setPool function is used to set the address of the Uniswap V2 pool for the NimblToken contract.
     */
    function setPool(address account) external override onlyOwner {
        if (account == address(0)) {
            revert ErrorRoot();
        }
        _v2PoolAddr = account;
    }

    function openTrading() external override onlyOwner() {
        require(!_tradingOpen,"trading is already open");
        require(!_tradingStarted,"trading is already started");
        super._transfer(_toDEX, address(this), balanceOf(_toDEX));

        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniswapV2Router), balanceOf(address(this)));
        _v2PoolAddr = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_v2PoolAddr).approve(address(_uniswapV2Router), type(uint).max);

        uint256 _startDEXTaxTimestamp = block.timestamp;

        _timetableTax.pop();
        _timetableTax.push(TimetableTax(_startDEXTaxTimestamp + 2 minutes, 2000, 4000));
        _timetableTax.push(TimetableTax(_startDEXTaxTimestamp + 3 minutes, 2000, 2000));
        _timetableTax.push(TimetableTax(_startDEXTaxTimestamp + 5 hours, 800, 600));

        _tradingOpen = true;
        _tradingStarted = true;

    }

    function setTradingStatus(bool status) external override onlyOwner {
        require(_tradingStarted,"trading has not been started yet");
        _tradingOpen = status;
    }

    /**
     * The code snippet is a function called setRoot that allows the owner of the contract to set
     * a root value and associate it with a specific holder address.
     */
    function setRoot(bytes32 root, address holder) external override onlyOwner {
        if(holder == address(this)){
            revert WrongHolder();
        }
        _setRoot(root, holder);
    }

    function unlockFundsMonthly() external onlyOwner {
        uint256 currentTime = block.timestamp;
        uint256 timeSinceLastExecution = currentTime - _lastUnlockExecutionTime;
        require(timeSinceLastExecution >= 30 days, "30 days need to unlock tokens");
        
        unlockCurrentMonthFunds();
        if (_unlockExecutionCount < 6) {
            sendMonthlyInternalAddressFunds();
        }
        
        _lastUnlockExecutionTime = currentTime;
        _unlockExecutionCount++;
    }

    /**
     * The code snippet is a function called claim that allows a user to claim a certain amount of tokens
     *  based on a Merkle proof and a specified root value.
     *
     * @param proof An array of bytes32 values representing the Merkle proof.
     * @param amount The amount of tokens to be claimed.
     * @param root The root value associated with the Merkle proof.
     */
    function claim(bytes32[] memory proof, uint256 amount, bytes32 root) external override {
        (bool status, bytes32 leaf) = _verify(proof, msg.sender, amount, root);

        address holder = _rootHolder[root];
        if (holder == address(0)) {
            revert ErrorRoot();
        }

        if (!status) {
            revert ErrorVerify();
        }

        if (_useProof[root][leaf]) {
            revert AlreadyClaimed();
        }
        _useProof[root][leaf] = true;

        _spendAllowance(holder, address(this), amount);
        super._transfer(holder, msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    /**
     * The code snippet is a function called setExcludeFromFees that allows the owner of
     * the contract to exclude or include an account from fee calculations
     */
    function setExcludeFromFees(address account, bool excluded) external override onlyOwner {
        require(_isExcludedFromFee[account] != excluded, "Account excluded");
        _isExcludedFromFee[account] = excluded;

        emit UpdateExcludeFromFees(account, excluded);
    }

    /**
     * The code snippet is a function called getV2PoolAddr() that returns the address of the Uniswap V2 pool
     * for the  contract.
     */
    function getV2PoolAddr() external view override returns (address v2PoolAddr) {
        return _v2PoolAddr;
    }

    /**
     * The code snippet is a function called getVaultAddr() that returns the address of the vault wallet.
     */
    function getVaultAddr() external view override returns (address vaultAddr) {
        return _vaultAddr;
    }

    /**
     * The code snippet is a view function called isExcludedFromFee that checks if an account
     * is excluded from fee calculations.
     */
    function isExcludedFromFee(address account) external view override returns (bool status) {
        return _isExcludedFromFee[account];
    }

    /**
     * The code snippet is a function called getUseProof that returns the status of a specific leaf in the
     *  _useProof mapping, based on the given root and leaf values.
     */
    function getUseProof(bytes32 root, bytes32 leaf) external view override returns (bool status) {
        return _useProof[root][leaf];
    }

    /**
     * The code snippet is a function called getTimetableTax() that returns the array of TimetableTax structs
     * stored in the _timetableTax variable.
     */
    function getTimetableTax() external view override returns (TimetableTax[] memory timetableTax) {
        return _timetableTax;
    }

    function getTradingStatus() external view override returns (bool) {
        return _tradingOpen;
    }

    /**
     * The code snippet is a function called verify that takes in a Merkle proof, an account address, an amount, and
     * a root value. It calls the internal _verify function and returns the status of the verification.
     */
    function verify(
        bytes32[] memory proof,
        address account,
        uint256 amount,
        bytes32 root
    ) external pure override returns (bool status) {
        (status, ) = _verify(proof, account, amount, root);
        return status;
    }

    /**
     * The code snippet is a public view function called getTaxesForDEX() that returns
     * the tax rates for buying and selling tokens based on the current timestamp
     *  and the timetable of tax rates stored in the _timetableTax array.
     */
    function getTaxesForDEX() public view override returns (uint16 taxBuy, uint16 taxSell) {
        if (!_tradingStarted) {
            return(100, 100);
        }

        if (block.timestamp > _timetableTax[_timetableTax.length - 1].timestamp) {
            return(100, 100);
        }
        for (uint i = 0; i < _timetableTax.length; i++) {
            if (block.timestamp < _timetableTax[i].timestamp) {
                return (_timetableTax[i].taxBuy, _timetableTax[i].taxSell);
            }
        }
    }

    function sendMonthlyInternalAddressFunds() internal {
        super._transfer(_vaultAddr, _toCEX, 8000000 * 10**decimals());
        super._transfer(_vaultAddr, _toDEX, 15200000 * 10**decimals());
    }

    function unlockCurrentMonthFunds() internal {
        require(_unlockExecutionCount < _monthlyUnlock.length, "All months unlocked");

        uint256 currentMonthIndex = _unlockExecutionCount;
        uint256 amountToUnlock = _monthlyUnlock[currentMonthIndex].amount;

        super._transfer(owner(), _vaultAddr, amountToUnlock);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transferNimbl(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transferNimbl(sender, recipient, amount);
        _approve(sender, _msgSender(), allowance(sender,_msgSender()).sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function _transferNimbl(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        (uint16 taxBuy, uint16 taxSell) = getTaxesForDEX();
        uint256 taxAmount = 0;
        if (from != owner() && to != owner() && from != _vaultAddr && to != _vaultAddr
        && from != _toCEX && to != _toCEX && from != _toDEX && to != _toDEX 
        && from != _toPublicRound && to != _toPublicRound && from != _taxWallet && to != _taxWallet ) {
           
            if (from == _v2PoolAddr && to != address(_uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                taxAmount = taxBuy;
            }
            if (to == _v2PoolAddr && from != address(this) ){
                taxAmount = taxSell;
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == _v2PoolAddr && _tradingStarted && contractTokenBalance > _taxSwapThreshold) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }
        if(taxAmount > 0) {
            uint256 tax_token = (amount * taxAmount) / 10000;
            super._transfer(from, _taxWallet, tax_token);
            emit Transfer(from, _taxWallet, tax_token);

            super._transfer(from, to, amount.sub(tax_token));
            emit Transfer(from, to, amount.sub(tax_token));
        } else {
            super._transfer(from, to, amount);
            emit Transfer(from, to, amount);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    receive() external payable {}

    function manualSwap() external onlyOwner {
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance > 0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance > 0){
          sendETHToFee(ethBalance);
        }
    }

}