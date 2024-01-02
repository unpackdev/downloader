// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUnikuraMigration {
    event CollectionChanged(address indexed oldToken, address indexed token);

    event MerkleRootChanged(bytes32 indexed oldMerkleRoot, bytes32 indexed merkleRoot);

    event Migrate(address indexed account, address indexed oldCollection, uint256 indexed tokenId);

    function setCollection(address token) external;

    function setMerkleRoot(bytes32 _merkleRoot) external;

    function migrate(address oldToken, uint256 tokenId, bytes32[] memory proof) external;
}
