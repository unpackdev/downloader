// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Ownable2Step.sol";
import "./MerkleProofLib.sol";

import "./IERC20.sol";

contract BlurAirdrop2 is Ownable2Step {
    uint256 public immutable RECLAIM_PERIOD;
    IERC20 public immutable TOKEN;
    address public immutable HOLDING;

    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public claimed;

    event Claimed(address indexed account, uint256 amount);

    error InvalidCaller();
    error TransferFailed();
    error TokensCannotBeReclaimed();
    error InvalidProof();
    error AirdropAlreadyClaimed();

    constructor(address token, address holding, uint256 reclaimDelay, bytes32 _merkleRoot) {
        TOKEN = IERC20(token);
        HOLDING = holding;
        RECLAIM_PERIOD = block.timestamp + reclaimDelay;
        merkleRoot = _merkleRoot;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(address account, uint256 amount, bytes32[] calldata proof) external {
        if (msg.sender != HOLDING) {
            revert InvalidCaller();
        }

        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        if (claimed[leaf]) {
            revert AirdropAlreadyClaimed();
        }

        if (!MerkleProofLib.verify(proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }
        claimed[leaf] = true;

        bool success = TOKEN.transfer(HOLDING, amount);
        if (!success) {
            revert TransferFailed();
        }

        emit Claimed(account, amount);
    }

    function reclaim(uint256 amount) external onlyOwner {
        if (block.timestamp < RECLAIM_PERIOD) {
            revert TokensCannotBeReclaimed();
        }
        bool success = TOKEN.transfer(msg.sender, amount);
        if (!success) {
            revert TransferFailed();
        }
    }
}
