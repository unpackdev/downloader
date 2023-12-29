// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IERC20Mintable.sol";
import "./IILVPool.sol";
import "./IFactory.sol";

error AlreadyClaimed();
error AlreadyPaused();
error InvalidProof();
error IsPaused();
error NotFactoryController();
error ZeroAddress();
error ZeroBytes();

/**
 * @title MerkleDistributor
 *
 * @dev Contract used to rewards users with their missing ILV rewards.
 * @dev Serves as "virtual" pool with 0 weight to be registered via PoolFactory.registerPool()
 *      so that the users can claim their rewards via ILVPool.stakeAsPool().
 * @dev This contract can be paused by the owner, for example when staking program finishes.
 */
contract MerkleDistributor {
    // This is a packed array of booleans for the Merkle Tree
    mapping(uint256 => uint256) private _claimedBitMap;

    // Address of the factory contract, used to check if the caller is the owner
    IFactory private immutable _factory;

    // Address of the ILV pool contract, used to call stakeAsPool()
    IILVPool public immutable ilvPool;

    // Whether the contract is paused so that new claims are not allowed
    bool public isPaused;

    // Merkle root used for the distribution
    bytes32 public merkleRoot;

    // below fields make this contract compatible with ILVPool.stakeAsPool()
    address public immutable poolToken; // ILV token address
    bool public constant isFlashPool = false;
    uint32 public constant weight = 0; // needs to be 0 so pool weights are not altered when registering

    // Claimed is emitted whenever a call to claim() succeeds
    event Claimed(uint256 index, address indexed account, uint256 amount);

    // SetMerkleRoot is emitted whenever the merkle root is set
    event SetMerkleRoot(address by, bytes32 merkleRoot);

    // Paused/Unpaused are emitted whenever the contract is paused/unpaused
    event Paused(address by);
    event Unpaused(address by);

    /**
     * @dev modifier to check if the caller is the factory controller
     */
    modifier isFactoryController() {
        if (msg.sender != _factory.owner()) revert NotFactoryController();
        _;
    }

    /**
     * @dev validate and set required parameters
     * @param factory_ factory address used for access control, must be non-zero
     * @param ilv_ ILV address used as poolToken, must be non-zero
     * @param ilvPool_ ILV pool address used to call stakeAsPool(), must be non-zero
     * @param merkleRoot_ merkle root, must be non-zero
     */
    constructor(IFactory factory_, address ilv_, IILVPool ilvPool_, bytes32 merkleRoot_) {
        if (address(factory_) == address(0)) revert ZeroAddress();
        if (ilv_ == address(0)) revert ZeroAddress();
        if (address(ilvPool_) == address(0)) revert ZeroAddress();
        if (merkleRoot_ == bytes32(0)) revert ZeroBytes();
        _factory = factory_;
        poolToken = ilv_;
        ilvPool = ilvPool_;
        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(msg.sender, merkleRoot_);
    }

    /**
     * @dev checks whether an index have been already claimed
     * @param index index to be checked
     * @return boolean claim status
     */
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /**
     * @dev mark the index as claimed in a gas-efficient way
     * @param index index to be marked
     */
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _claimedBitMap[claimedWordIndex] = _claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
     * @dev Set paused/unpaused state in the contract
     * @notice Can only be called by the owner
     * @param shouldPause whether the contract should be paused/unpausd
     */
    function pause(bool shouldPause) external isFactoryController {
        if ((isPaused && shouldPause) || (!isPaused && !shouldPause)) revert AlreadyPaused();
        if (shouldPause) {
            isPaused = true;
            emit Paused(msg.sender);
        } else {
            isPaused = false;
            emit Unpaused(msg.sender);
        }
    }

    /**
     * @dev Sets the yield weight tree root
     * @notice Can only be called by the owner
     * @param merkleRoot_ 32 bytes tree root, must be non-zero
     */
    function setMerkleRoot(bytes32 merkleRoot_) external isFactoryController {
        if (merkleRoot_ == bytes32(0)) revert ZeroBytes();
        merkleRoot = merkleRoot_;
        emit SetMerkleRoot(msg.sender, merkleRoot_);
    }

    /**
     * @dev verifies the parameters and stakes the ILV if not yet claimed
     * @param index index used for claiming
     * @param amount amount of tokens to be claimed and staked
     * @param proof bytes32 array with the merkle proof generated off-chain
     */
    function claim(uint256 index, uint256 amount, bytes32[] calldata proof) external virtual {
        // Revert if the contract is paused
        if (isPaused) revert IsPaused();
        // Revert if already claimed
        if (isClaimed(index)) revert AlreadyClaimed();

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
        if (!MerkleProof.verify(proof, merkleRoot, node)) revert InvalidProof();

        // Mark it claimed and stake claimed ILV
        _setClaimed(index);
        ilvPool.stakeAsPool(msg.sender, amount);

        emit Claimed(index, msg.sender, amount);
    }
}
