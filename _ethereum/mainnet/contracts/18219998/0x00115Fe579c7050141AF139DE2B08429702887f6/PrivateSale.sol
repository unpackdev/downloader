// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library MerkleProof {
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
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
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
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
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
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

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
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
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
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

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
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


interface IERC20 {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
    // Add other ERC20 methods as needed
}

contract PrivateSale {
    IERC20 public goatyToken;
    uint256 public constant HARD_CAP = 50 ether;
    uint256 public constant MAX_BUY = 1 ether;
    uint256 public constant TOTAL_SALE_AMOUNT = 48_594_000_000_000 * 10 ** 18;
    uint256 public constant PRICE = (HARD_CAP * 1e18) / TOTAL_SALE_AMOUNT;
    address public constant GOATY_TOKEN_ADDRESS = 0x9aAEffDe3287fc455E63aE0b73eDc480D7b5Eb89;

    bytes32 public merkleRoot;

    /**
     * @notice The address of the deployer, which will receive the raised ETH.
     */
    address public immutable owner;

    /**
     * @notice The address of the recipient, which will receive the raised ETH.
     */
    address public immutable recipient = 0x1e316b28Bd973B50A266e879D079F18331429227;

    /**
     * @notice Whether the sale has ended.
     */
    bool public saleEnded;

    /**
     * @notice The total amount of tokens bought.
     */
    uint256 public totalTokensBought;

    /**
     * @notice The total amount of ETH allocated.
     */
    uint256 public totalETHallocated;

    /**
     * @notice The start date of the sale in unix timestamp.
     */
    uint256 public start;

    /**
     * @notice The end date of the sale in unix timestamp.
     */
    uint256 public end;

    /**
     * @notice The amount of tokens bought by each address.
     */
    mapping(address => uint256) public amountBought;

    /**
     * @notice The amount of bnb bought by each address.
     */
    mapping(address => uint256) public ethAllocated;

    /**
     * @notice Emits when tokens are bought.
     * @param buyer The address of the buyer.
     * @param amount The amount of tokens bought.
     */

    event TokensBought(address indexed buyer, uint256 amount);

    /**
     * @notice Emits when the root change.
     * @param newRoot The address of the buyer.
     */

    event MerkleRootChanged(bytes32 indexed newRoot);

    /**
     * @notice Emits when tokens are claimed.
     * @param claimer The address of the claimer.
     * @param amount The amount of tokens claimed.
     */
    event TokensClaimed(address indexed claimer, uint256 amount);

    /**
     * @notice Emits when the token address is updated.
     * @param newTokenAddress The address of the new token.
     */
    event TokenAddressUpdated(address newTokenAddress);

    /**
     * @notice Emits when ETH is refunded.
     * @param buyer The address of the buyer.
     * @param amount The amount of ETH refunded.
     */
    event EthRefunded(address indexed buyer, uint256 amount);

    /**
     * @notice Emits when the sale is ended.
     * @param totalAmountBought The total amount of tokens bought.
     */
    event SaleEnded(uint256 totalAmountBought);

    constructor(bytes32 _merkleRoot, uint256 _start, uint256 _end) {
        require(_merkleRoot != bytes32(0), "Merkle root cannot be empty");

        start = _start;
        end = _end;
        owner = msg.sender;
        merkleRoot = _merkleRoot;
        goatyToken = IERC20(GOATY_TOKEN_ADDRESS);  
    }

    /**
     * @notice Change token address.
     * @param  The address of the new token.
     */

    /**
     * @notice Change the root by owner
     */

    function changeRoot(bytes32 _newRoot) public {
        require(owner == msg.sender, "Only owner can change the root");
        require(_newRoot != bytes32(0), "Merkle root cannot be empty");
        merkleRoot = _newRoot;
        emit MerkleRootChanged(_newRoot);
    }

    /**
     * @notice Buys tokens with ETH.
     */
    function buy(bytes32[] calldata _proof) external payable {
        require(block.timestamp >= start, "Sale has not started yet");
        require(block.timestamp <= end, "Sale has ended");
        require(msg.value > 0, "Amount must be greater than 0");
        require(!saleEnded, "Sale has ended");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_proof, merkleRoot, node), "Invalid proof");

        require(
            msg.value <= MAX_BUY - ethAllocated[msg.sender],
            "Amount must be less than the maximum buy"
        );

        // Compute the amount of tokens bought
        uint256 tokensBought = (msg.value * 10 ** 18) / PRICE;

        require(
            totalETHallocated + msg.value <= HARD_CAP,
            "Hard cap has been reached"
        );

        // Update the storage variables
        amountBought[msg.sender] += tokensBought;
        ethAllocated[msg.sender] += msg.value;
        totalTokensBought += tokensBought;
        totalETHallocated += msg.value;

        emit TokensBought(msg.sender, tokensBought);
    }

    /**
     * @notice If the soft cap is reached, sens the TGE tokens to the user and creates a vesting schedule for the rest.
     * If the soft cap is not reached, sends the ETH back to the user.
     * @param _buyers The addresses of the buyers.
     */
    function airdrop(
        address[] calldata _buyers
    ) external {
        require(saleEnded, "Sale has not ended yet");
        require(msg.sender == owner, "Only owner can call this function");


        for (uint256 i = 0; i < _buyers.length; i++) {
            // Check if the buyer has bought tokens
            uint256 tokensBought = amountBought[_buyers[i]];
            if (tokensBought == 0) continue;

            // Reset the amount bought
            amountBought[_buyers[i]] = 0;

            // Send the TGE tokens
            goatyToken.transfer(_buyers[i], tokensBought);
            emit TokensClaimed(_buyers[i], tokensBought);
        }
    }

    function refund(address[] calldata _buyers) external {
        require(saleEnded, "Sale has not ended yet");
        require(msg.sender == owner, "Only owner can call this function");

        for (uint256 i = 0; i < _buyers.length; i++) {
            // Check if the buyer has bought tokens
            uint256 tokensBought = amountBought[_buyers[i]];
            if (tokensBought == 0) continue;

            // Reset the amount bought
            amountBought[_buyers[i]] = 0;

            // Compute the amount of ETH to refund and send it back to the buyer
            uint256 amountToRefund = (tokensBought * PRICE) / 10 ** 18;

            (bool sc, ) = payable(_buyers[i]).call{value: amountToRefund}("");
            require(sc, "Transfer failed");

            emit EthRefunded(_buyers[i], amountToRefund);
        }
    }

    /**
     * @notice Ends the sale.
     */
    function endSale() external {
        require(block.timestamp > end, "Sale has not ended yet");
        require(!saleEnded, "Sale has already ended");

        // Mark the sale as ended
        saleEnded = true;

        // Send the raised ETH to the recipient
        (bool sc, ) = payable(recipient).call{value: address(this).balance}("");
        require(sc, "Transfer failed");

        emit SaleEnded(totalTokensBought);
    }

    receive() external payable {}
}