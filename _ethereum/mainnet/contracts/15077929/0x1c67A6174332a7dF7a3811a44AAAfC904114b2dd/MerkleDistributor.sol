// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Initializable.sol";
import "./MerkleProofUpgradeable.sol";

abstract contract MerkleDistributor {
    mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

    function isClaimed(bytes32 merkleRoot, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleRoot][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        mapping(uint256 => uint256) storage _claimedBitMap =
            claimedBitMap[merkleRoot];
        _claimedBitMap[claimedWordIndex] |= (1 << claimedBitIndex);
    }

    function _claim(
        bytes32 merkleRoot,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        require(
            !isClaimed(merkleRoot, index),
            "MerkleDistributor: already claimed"
        );
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: bad proof"
        );
        _setClaimed(merkleRoot, index);
    }
}
