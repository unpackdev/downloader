// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract RewardsDistributor is Ownable {
    using SafeERC20 for IERC20;

    address public immutable claimToken;
    bytes32 public merkleRoot;
    bool public canClaim;

    mapping(address => bytes32) public claimedRoots;
    mapping(bytes32 => uint256) public historyRoots;

    event ClaimedRoot(bytes32 merkleRoot, address account, uint256 amount);

    modifier whenClaimingPaused() {
        require(!canClaim, 'RD1');
        _;
    }

    modifier whenClaimingAllowed() {
        require(canClaim, 'RD2');
        _;
    }

    constructor(address tokenToBeDistributed) public Ownable() {
        claimToken = tokenToBeDistributed;
    }

    function pauseClaiming() external onlyOwner whenClaimingAllowed {
        canClaim = false;
    }

    function setMerkleRoot(bytes32 newMerkleRoot, uint256 lastBlockConsidered) external onlyOwner whenClaimingPaused {
        require(historyRoots[newMerkleRoot] == 0, 'RD3');
        historyRoots[newMerkleRoot] = lastBlockConsidered;
        merkleRoot = newMerkleRoot;
        canClaim = true;
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) external whenClaimingAllowed {
        require(claimedRoots[msg.sender] != merkleRoot, 'RD4');
        bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'RD5');
        claimedRoots[msg.sender] = merkleRoot;
        IERC20(claimToken).safeTransfer(msg.sender, amount);
        emit ClaimedRoot(merkleRoot, msg.sender, amount);
    }
}
