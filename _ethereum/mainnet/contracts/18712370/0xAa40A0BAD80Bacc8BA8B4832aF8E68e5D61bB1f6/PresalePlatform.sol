// File: @openzeppelin/contracts@4.9.3/utils/cryptography/MerkleProof.sol


// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
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

// File: @openzeppelin/contracts@4.9.3/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// File: @openzeppelin/contracts@4.9.3/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: @openzeppelin/contracts@4.9.3/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/KusaPresale.sol


pragma solidity ^0.8.9;




contract PresalePlatform is Ownable {
    uint256 public constant PRESALE_ALLOCATION = 60_000_000;
    uint256 public constant PRESALE_AMOUNT = 160; // Amount of Ether raised in presale
    uint256 public constant PRICE_PER_TOKEN = (PRESALE_AMOUNT * 1e18) / PRESALE_ALLOCATION;

    // Main token Contract
    IERC20 public tokenContract;

    // Phase 1 sale state and parameters
    bool public phase1State = true;
    uint256 public phase1Cap = 120 ether;
    uint256 public phase1TotalDeposits = 0;
    uint256 public phase1MaxDeposit = 1 ether;
    uint256 public phase1MinDeposit = 0.3 ether;
    mapping(address => uint256) private phase1UserBalance;
    bytes32 public phase1MerkleRoot;

    // Phase 2 sale state and parameters
    bool public phase2State = false;
    uint256 public phase2Cap = 40 ether;
    uint256 public phase2TotalDeposits = 0;
    uint256 public phase2MaxDeposit = 0.3 ether;
    mapping(address => uint256) private phase2UserBalance;

    // Global state
    bool public claims = false;
    mapping(address => bool) private userClaims;
    mapping(address => uint256) private totalContribution;

    // Events to log deposit transactions
    event DepositPhase1(address indexed _from, uint _value);
    event DepositPhase2(address indexed _from, uint _value);

    // Modifier to check if the sale is enabled
    modifier saleEnabled(bool saleState) {
        require(saleState, "Sale is not currently enabled");
        _;
    }

    constructor() {}

    function getSaleData() public view returns (bool, uint256, uint256, uint256, uint256, bool, uint256, uint256, uint256, bool) {
        return (
            phase1State,
            phase1Cap,
            phase1TotalDeposits,
            phase1MaxDeposit,
            phase1MinDeposit,
            phase2State,
            phase2Cap,
            phase2TotalDeposits,
            phase2MaxDeposit,
            claims
        );
    }

    function getKusa(uint256 investment) internal pure returns (uint256) {
        return investment / PRICE_PER_TOKEN;
    }

    function getKusaOwed(address user) external view returns (uint256) {
        uint256 totalContributions = totalContribution[user];
        return totalContributions > 0 ? getKusa(totalContributions) : 0;
    }

    // Function for depositing in Phase 1 with Merkle proof verification
    function depositPhase1(bytes32[] calldata proof) public payable saleEnabled(phase1State) {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        if (phase1UserBalance[msg.sender] < phase1MinDeposit) {
            require(msg.value >= phase1MinDeposit, "Deposit amount is below the minimum required");
        }

        require((phase1TotalDeposits + msg.value) <= phase1Cap, "Exceeds Phase 1 cap");
        require((phase1UserBalance[msg.sender] + msg.value) <= phase1MaxDeposit, "Exceeds User maximum deposit amount");
        require(_verify(_leaf(msg.sender), proof), "Invalid proof");

        phase1TotalDeposits += msg.value;
        phase1UserBalance[msg.sender] += msg.value;
        totalContribution[msg.sender] += msg.value;
        emit DepositPhase1(msg.sender, msg.value);
    }

    // Function for depositing in Phase 2
    function depositPhase2() public payable saleEnabled(phase2State) {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        require((phase2TotalDeposits + msg.value) <= phase2Cap, "Exceeds Phase 2 cap");
        require((phase2UserBalance[msg.sender] + msg.value) <= phase2MaxDeposit, "Exceeds User maximum deposit amount");

        phase2TotalDeposits += msg.value;
        phase2UserBalance[msg.sender] += msg.value;
        totalContribution[msg.sender] += msg.value;
        emit DepositPhase2(msg.sender, msg.value);
    }

    function getClaimData(address user) public view returns (bool) {
        return userClaims[user];
    }

    function claimTokens() public {
        require(claims, "Claims not enabled");
        require(!userClaims[msg.sender], "User has already claimed!");
        uint256 totalDeposits = phase1TotalDeposits + phase2TotalDeposits;
        require(totalDeposits > 0, "Total deposits must be greater than zero");
        uint256 totalContributions = totalContribution[msg.sender];
        require(totalContributions > 0, "User has no contributions to claim");

        uint256 userAllocation = getKusa(totalContributions) * 1 ether;

        // Transfer tokens
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance >= userAllocation, "Contract does not have enough tokens to claim");

        userClaims[msg.sender] = true;
        tokenContract.transfer(msg.sender, userAllocation);
    }

    // Enable disable Claims
    function setClaimState(bool _state) public onlyOwner {
        claims = _state;
    }

    function setPhaseState(bool isPhase1, bool _state) public onlyOwner {
        if(isPhase1){
            phase1State = _state;
        }else{
            phase2State = _state;
        }
    }

    // Function to get the deposited amount for a user in a specific phase
    function getUserDepositedAmount(address _user, uint256 _phase) public view returns (uint256) {
        if (_phase == 1) {
            return phase1UserBalance[_user];
        } else if (_phase == 2) {
            return phase2UserBalance[_user];
        } else {
            return totalContribution[_user];
        }
    }

    function setTokenContract(address _contract) public onlyOwner {
        tokenContract = IERC20(_contract);
    }

    // Function to set Phase 1 sale settings
    function setPhase1Settings(bool _sale, uint256 _phase1Cap, uint256 _phase1MaxDeposit, uint256 _phase1MinDeposit) public onlyOwner {
        require(_phase1Cap > 0, "Phase 1: Cap should be greater than zero");
        require(_phase1MaxDeposit > 0, "Phase 1: Max Deposit should be greater than zero");
        phase1State = _sale;
        phase1Cap = _phase1Cap;
        phase1MaxDeposit = _phase1MaxDeposit;
        phase1MinDeposit = _phase1MinDeposit;
    }

    // Function to set Phase 2 sale settings
    function setPhase2Settings(bool _sale, uint256 _phase2Cap, uint256 _phase2MaxDeposit) public onlyOwner {
        require(_phase2Cap > 0, "Phase 2: Cap should be greater than zero");
        require(_phase2MaxDeposit > 0, "Phase 2: Max Deposit should be greater than zero");
        phase2State = _sale;
        phase2Cap = _phase2Cap;
        phase2MaxDeposit = _phase2MaxDeposit;
    }

    // Function to set the Phase 1 Merkle root for proof verification
    function setPhase1MerkleRoot(bytes32 _root) public onlyOwner {
        phase1MerkleRoot = _root;
    }

    // Internal function to verify Merkle proof
    function _verify(bytes32 _leafNode, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, phase1MerkleRoot, _leafNode);
    }

    // Internal function to generate the leaf node
    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(0xb62A384c628E328Fc703E945B3Df992e8BE6ffa2).transfer(balance);
    }
}