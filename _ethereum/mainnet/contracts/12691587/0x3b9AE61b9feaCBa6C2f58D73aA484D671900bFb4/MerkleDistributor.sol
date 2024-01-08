pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Pausable.sol";

contract InstaMerkleDistributorLM is AccessControl, Pausable {
    using SafeMath for uint256;

    struct MerkleData {
        bytes32 root;
        bytes32 contentHash;
        uint256 timestamp;
        uint256 publishBlock;
        uint256 startBlock;
        uint256 endBlock;
    }

    bytes32 public constant ROOT_PROPOSER_ROLE = keccak256("ROOT_PROPOSER_ROLE");

    IERC20 public constant token = IERC20(0x6f40d4A6237C257fff2dB00FA0510DeEECd303eb);

    uint256 public currentCycle;
    bytes32 public merkleRoot;
    bytes32 public merkleContentHash;
    uint256 public lastPublishTimestamp;
    uint256 public lastPublishBlockNumber;

    uint256 public pendingCycle;
    bytes32 public pendingMerkleRoot;
    bytes32 public pendingMerkleContentHash;
    uint256 public lastProposeTimestamp;
    uint256 public lastProposeBlockNumber;

    bytes32 public prevMerkleRoot;

    mapping(address => uint256) public claimed;

    uint256 public lastPublishStartBlock;
    uint256 public lastPublishEndBlock;

    uint256 public lastProposeStartBlock;
    uint256 public lastProposeEndBlock;

    event Claimed(address indexed user, uint256 amount, uint256 indexed cycle, uint256 timestamp, uint256 blockNumber);
    event RootProposed(uint256 indexed cycle, bytes32 indexed root, bytes32 indexed contentHash, uint256 timestamp, uint256 blockNumber);
    event RootUpdated(uint256 indexed cycle, bytes32 indexed root, bytes32 indexed contentHash, uint256 timestamp, uint256 blockNumber);

    constructor(address admin_, address proposer_) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin_); // The admin can edit all role permissions
        _setupRole(ROOT_PROPOSER_ROLE, proposer_); // The proposer can propose root
    }

    /// @notice Admins can approve new root updaters or admins
    function _onlyAdmin() internal view {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "onlyAdmin");
    }

    /// @notice Root updaters can update the root
    function _onlyRootProposer() internal view {
        require(hasRole(ROOT_PROPOSER_ROLE, msg.sender), "onlyRootProposer");
    }

    function getCurrentMerkleData() external view returns (MerkleData memory) {
        return
            MerkleData(
                merkleRoot,
                merkleContentHash,
                lastPublishTimestamp,
                lastPublishBlockNumber,
                lastPublishStartBlock,
                lastPublishEndBlock
            );
    }

    function getPendingMerkleData() external view returns (MerkleData memory) {
        return
            MerkleData(
                pendingMerkleRoot,
                pendingMerkleContentHash,
                lastProposeTimestamp,
                lastProposeBlockNumber,
                lastProposeStartBlock,
                lastProposeEndBlock
            );
    }

    function hasPendingRoot() external view returns (bool) {
        return pendingCycle == currentCycle.add(1);
    }

    function getClaimed(address user) public view returns (uint256 totalClaimed) {
        totalClaimed = claimed[user];
    }

    function encodeClaim(
        uint256 cumulativeAmount,
        address account,
        uint256 index,
        uint256 cycle
    ) public view returns (bytes memory encoded, bytes32 hash) {
        encoded = abi.encode(index, account, cycle, cumulativeAmount);
        hash = keccak256(encoded);
    }

    function claim(
        address recipient,
        uint256 cumulativeAmount,
        uint256 index,
        uint256 cycle,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(cycle == currentCycle || cycle == currentCycle.sub(1), "Invalid cycle");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encode(index, recipient, cycle, cumulativeAmount));
        
        if (cycle == currentCycle) {
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
        } else {
            require(MerkleProof.verify(merkleProof, prevMerkleRoot, node), "Invalid proof");
        }

        uint256 claimable = cumulativeAmount.sub(claimed[recipient]);

        require(claimable > 0, "No tokens to claim");

        claimed[recipient] = claimed[recipient].add(claimable);

        require(claimed[recipient] == cumulativeAmount, "Claimed amount mismatch");
        require(token.transfer(recipient, claimable), "Transfer failed");

        emit Claimed(recipient, claimable, cycle, block.timestamp, block.number);
    }

    // ===== Root Updater Restricted =====

    /// @notice Propose a new root and content hash, which will be stored as pending until approved
    function proposeRoot(
        bytes32 root,
        bytes32 contentHash,
        uint256 cycle,
        uint256 startBlock,
        uint256 endBlock
    ) external whenNotPaused {
        _onlyRootProposer();

        require(cycle == currentCycle.add(1), "Incorrect cycle");

        pendingCycle = cycle;
        pendingMerkleRoot = root;
        pendingMerkleContentHash = contentHash;
        lastProposeStartBlock = startBlock;
        lastProposeEndBlock = endBlock;

        lastProposeTimestamp = block.timestamp;
        lastProposeBlockNumber = block.number;

        emit RootProposed(cycle, pendingMerkleRoot, pendingMerkleContentHash, block.timestamp, block.number);
    }

    /// ===== Admin Restricted =====

    /// @notice Approve the current pending root and content hash

    function approveRoot(
        bytes32 root,
        bytes32 contentHash,
        uint256 cycle,
        uint256 startBlock,
        uint256 endBlock
    ) external {
        _onlyAdmin();

        require(root == pendingMerkleRoot, "Incorrect root");
        require(contentHash == pendingMerkleContentHash, "Incorrect content hash");
        require(cycle == pendingCycle, "Incorrect cycle");

        require(startBlock == lastProposeStartBlock, "Incorrect cycle start block");
        require(endBlock == lastProposeEndBlock, "Incorrect cycle end block");

        prevMerkleRoot = merkleRoot;

        currentCycle = cycle;
        merkleRoot = root;
        merkleContentHash = contentHash;
        lastPublishStartBlock = startBlock;
        lastPublishEndBlock = endBlock;

        lastPublishTimestamp = block.timestamp;
        lastPublishBlockNumber = block.number;

        emit RootUpdated(currentCycle, root, contentHash, block.timestamp, block.number);
    }

    function spell(address _target, bytes memory _data) public {
        _onlyAdmin();
        require(_target != address(0), "target-invalid");
        assembly {
        let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
        switch iszero(succeeded)
            case 1 {
                let size := returndatasize()
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }

    /// @notice Pause publishing of new roots
    function pause() external {
        _onlyAdmin();
        _pause();
    }

    /// @notice Unpause publishing of new roots
    function unpause() external {
        _onlyAdmin();
        _unpause();
    }
}
