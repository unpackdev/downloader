// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./IVotingIdentity.sol";
import "./IGate.sol";
import "./MerkleLib.sol";

contract GatedMerkleIdentity {
    using MerkleLib for *;

    struct MerkleTree {
        bytes32 addressMerkleRoot;
        bytes32 metadataMerkleRoot;
        bytes32 leafHash;
        address nftAddress;
        address gateAddress;
    }

    mapping (uint => MerkleTree) public merkleTrees;
    uint public numTrees;

    address public management;

    mapping (uint => mapping(address => bool)) public withdrawn;

    event ManagementUpdated(address oldManagement, address newManagement);
    event MerkleTreeAdded(uint indexed index, address indexed nftAddress);

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor(address _mgmt) {
        management = _mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function addMerkleTree(bytes32 addressMerkleRoot, bytes32 metadataMerkleRoot, bytes32 leafHash, address nftAddress, address gateAddress) external managementOnly {
        MerkleTree storage tree = merkleTrees[++numTrees];
        tree.addressMerkleRoot = addressMerkleRoot;
        tree.metadataMerkleRoot = metadataMerkleRoot;
        tree.leafHash = leafHash;
        tree.nftAddress = nftAddress;
        tree.gateAddress = gateAddress;
        emit MerkleTreeAdded(numTrees, nftAddress);
    }

    function withdraw(uint merkleIndex, string memory uri, bytes32[] memory addressProof, bytes32[] memory metadataProof) external payable {
        MerkleTree storage tree = merkleTrees[merkleIndex];
        IVotingIdentity id = IVotingIdentity(tree.nftAddress);
        uint tokenId = id.numIdentities() + 1;

        require(merkleIndex <= numTrees, 'merkleIndex out of range');
        require(verifyEntitled(tree.addressMerkleRoot, msg.sender, addressProof), "The address proof could not be verified.");
        require(verifyMetadata(tree.metadataMerkleRoot, tokenId, uri, metadataProof), "The metadata proof could not be verified");
        require(!withdrawn[merkleIndex][msg.sender], "You have already withdrawn your nft from this merkle tree.");

        // close re-entrance gate, prevent double withdrawals
        withdrawn[merkleIndex][msg.sender] = true;

        // pass thru the gate
        IGate(tree.gateAddress).passThruGate{value: msg.value}();

        // mint an identity
        id.createIdentityFor(msg.sender, tokenId, uri);
    }

    function getNextTokenId(uint merkleIndex) public view returns (uint) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        IVotingIdentity id = IVotingIdentity(tree.nftAddress);
        uint tokenId = id.totalSupply() + 1;
        return tokenId;
    }

    function getPrice(uint merkleIndex) public view returns (uint) {
        MerkleTree memory tree = merkleTrees[merkleIndex];
        uint ethCost = IGate(tree.gateAddress).getCost();
        return ethCost;
    }

    // mostly for debugging
    function getLeaf(address data1, string memory data2) external pure returns (bytes memory) {
        return abi.encode(data1, data2);
    }

    // mostly for debugging
    function getHash(address data1, string memory data2) external pure returns (bytes32) {
        return keccak256(abi.encode(data1, data2));
    }

    function verifyEntitled(bytes32 root, address recipient, bytes32[] memory proof) public pure returns (bool) {
        // We need to pack the 20 bytes address to the 32 bytes value
        bytes32 leaf = keccak256(abi.encode(recipient));
        return root.verifyProof(leaf, proof);
    }

    function verifyMetadata(bytes32 root, uint tokenId, string memory uri, bytes32[] memory proof) public pure returns (bool) {
        bytes32 leaf = keccak256(abi.encode(tokenId, uri));
        return root.verifyProof(leaf, proof);
    }

}