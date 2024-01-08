// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";
import "./Ownable.sol";

/** @title Paladin Merkle Aridrop contract  */
/// @author Paladin
/*
    Contract holds PAL ERC20 tokens, and allow elegible
    users to claim a given amount if a correct merkle proof is provided
*/
contract MerkleDistributor is IMerkleDistributor, Ownable {
    using SafeERC20 for IERC20;

    uint256 public immutable endTimestamp;

    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(
        address _admin,
        address _token,
        bytes32 _merkleRoot,
        uint256 _distributionDuration // in number of days
    ) {
        require(_admin != address(0), "MerkleDistributor: admin is address zero");
        require(_token != address(0), "MerkleDistributor: zero address");
        require(_merkleRoot != bytes32(0), "MerkleDistributor: invalid merkle root");
        require(_distributionDuration > 0, "MerkleDistributor: invalid duration");
        token = _token;
        merkleRoot = _merkleRoot;

        endTimestamp = block.timestamp + (_distributionDuration * 1 days);

        transferOwnership(_admin);
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof"
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC20(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount);
    }

    function recoverToken(address tokenAddress, uint256 amount) external onlyOwner {
        if(tokenAddress == token){
            // distribution token
            require(block.timestamp >= endTimestamp, "MerkleDistributor: Not allowed before end of distribution");
            IERC20(token).safeTransfer(owner(), amount);
        }
        else{
            // any other lost token
            IERC20(tokenAddress).safeTransfer(owner(), amount);
        }
    }
}