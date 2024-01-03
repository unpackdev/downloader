// File: @openzeppelin/contracts/cryptography/MerkleProof.sol

pragma solidity ^0.6.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/MerkleDistributor.sol

pragma solidity >=0.6.11;

interface IRMU {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external;
}

interface IMerkleDistributor {
    // Returns the address of the RMU used by this contract.
    function RMU() external view returns (IRMU);

    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoots(uint256 cardId) external view returns (bytes32);

    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 cardId, uint256 index)
        external
        view
        returns (bool);

    // Claim the given amount of the RMU to the given address. Reverts if the inputs are invalid.
    function claim(
        uint256 cardId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(
        uint256 cardId,
        uint256 index,
        address account,
        uint256 amount
    );
}

contract MerkleDistributor is IMerkleDistributor, Ownable {
    IRMU public immutable override RMU;

    // Mapping of cardIds to merkle roots
    mapping(uint256 => bytes32) public override merkleRoots;

    // Mapping of cardIds to packed array of booleans
    mapping(uint256 => mapping(uint256 => uint256)) private claimedBitMaps;

    constructor(IRMU _RMU) public {
        RMU = _RMU;
    }

    function addMerkleRoot(uint256 cardId, bytes32 merkleRoot)
        public
        onlyOwner
    {
        merkleRoots[cardId] = merkleRoot;
    }

    function isClaimed(uint256 cardId, uint256 index)
        public
        override
        view
        returns (bool)
    {
        mapping(uint256 => uint256) storage claimed = claimedBitMaps[cardId];

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 cardId, uint256 index) private {
        mapping(uint256 => uint256) storage claimed = claimedBitMaps[cardId];

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        claimed[claimedWordIndex] =
            claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 cardId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(
            !isClaimed(cardId, index),
            "MerkleDistributor: Drop already claimed."
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoots[cardId], node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the NFT.
        _setClaimed(cardId, index);

        RMU.mint(account, cardId, amount, "");

        emit Claimed(cardId, index, account, amount);
    }
}