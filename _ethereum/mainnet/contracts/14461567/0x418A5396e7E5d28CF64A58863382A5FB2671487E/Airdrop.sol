// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***
 *      _  _  _    ___   
 *     /_`/_//_//_///_// 
 *    /  / \/ //`\// //_,
 *                       
 */

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

import "./SafeERC20.sol";

contract FraktalLaunchPartnerAirdrop is Pausable, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable fraktalToken;
    uint256 public immutable MAXIMUM_AMOUNT_TO_CLAIM;

    bool public isMerkleRootSet;

    bytes32 public merkleRoot;

    uint256 public endTimestamp;

    uint256 public startBlock;

    mapping(address => bool) public hasClaimed;

    event AirdropRewardsClaim(address indexed user, uint256 amount);
    event MerkleRootSet(bytes32 merkleRoot);
    event NewEndTimestamp(uint256 endTimestamp);
    event TokensWithdrawn(uint256 amount);

    constructor(
        uint256 _startBlock,
        uint256 _endTimestamp,
        uint256 _maximumAmountToClaim,
        address _fraktalToken,
        bytes32 _merkleRoot
    ) {
        startBlock = _startBlock;//1648382400
        endTimestamp = _endTimestamp;//1649246400
        MAXIMUM_AMOUNT_TO_CLAIM = _maximumAmountToClaim;

        fraktalToken = IERC20(_fraktalToken);
        merkleRoot = _merkleRoot;
        isMerkleRootSet = true;
    }

    function claim(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused nonReentrant {
        require(isMerkleRootSet, "Airdrop: Merkle root not set");
        require(amount <= MAXIMUM_AMOUNT_TO_CLAIM, "Airdrop: Amount too high");
        require(block.timestamp > startBlock, "Airdrop: Too early to claim");
        require(block.timestamp <= endTimestamp, "Airdrop: Too late to claim");
        require(amount > 0, "Airdrop: Amount to low");

        // Verify the user has claimed
        require(!hasClaimed[msg.sender], "Airdrop: Already claimed");


        // Compute the node and verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender,amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Airdrop: Invalid proof");

        // Set as claimed
        hasClaimed[msg.sender] = true;

        // parse to Fraktal distribution
        uint256 frakAmount = amount * 10**18;

        // Transfer tokens
        fraktalToken.safeTransfer(msg.sender, frakAmount);

        emit AirdropRewardsClaim(msg.sender, frakAmount);
    }

    function canClaim(
        address user,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external view returns (bool) {
        if (block.timestamp <= endTimestamp) {
            // Compute the node and verify the merkle proof
            bytes32 node = keccak256(abi.encodePacked(user,amount));
            return MerkleProof.verify(merkleProof, merkleRoot, node);
        } else {
            return false;
        }
    }

    function pauseAirdrop() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseAirdrop() external onlyOwner whenPaused {
        _unpause();
    }

    function updateEndTimestamp(uint256 newEndTimestamp) external onlyOwner {
        require(block.timestamp + 30 days > newEndTimestamp, "Owner: New timestamp too far");
        endTimestamp = newEndTimestamp;

        emit NewEndTimestamp(newEndTimestamp);
    }

    function withdrawTokenRewards() external onlyOwner {
        require(block.timestamp > (endTimestamp + 1 days), "Owner: Too early to remove rewards");
        uint256 balanceToWithdraw = fraktalToken.balanceOf(address(this));
        fraktalToken.safeTransfer(msg.sender, balanceToWithdraw);

        emit TokensWithdrawn(balanceToWithdraw);
    }
}