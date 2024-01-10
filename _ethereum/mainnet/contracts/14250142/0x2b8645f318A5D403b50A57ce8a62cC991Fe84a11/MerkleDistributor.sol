//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./IERC20.sol";

/**
  Ref: https://github.com/Uniswap/merkle-distributor
 */
contract MerkleDistributor {
    bytes32 public immutable merkleRoot;
    IERC20 public token;
    address private DIARewards;
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Claimed(uint256 index, address account, uint256 amount);

    constructor(bytes32 _merkleRoot, address _tokenAddress, address _DIARewards) {
        merkleRoot = _merkleRoot;
        token = IERC20(_tokenAddress);
        DIARewards = _DIARewards;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }


    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        
        //transfer tokens from DIARewards to the account
        require(IERC20(token).transferFrom(DIARewards, account, amount), 'MerkleDistributor: Transfer failed.');

        // Mark it claimed 
        _setClaimed(index);

        emit Claimed(index, account, amount);
    }
}