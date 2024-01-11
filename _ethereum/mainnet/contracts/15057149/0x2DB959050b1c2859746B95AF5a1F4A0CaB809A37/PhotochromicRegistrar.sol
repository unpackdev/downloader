// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ENS.sol";
import "./Controllable.sol";
import "./ERC721Enumerable.sol";

import "./PhotochromicTools.sol";

contract PhotochromicRegistrar is ERC721Enumerable, Controllable {

    // The ENS registry.
    ENS public immutable ens;
    // The namehash of the TLD this registrar owns (e.g., `.eth`).
    bytes32 public baseNode;
    string public baseNodeString;

    // Mapping from the tokenId (ENS namehash) to IPFS metadata hash.
    mapping(uint256 => bytes32) hashes;
    // Mapping from the owner of a photochromic identity to ENS namehash.
    mapping(address => bytes32) nodes;

    constructor(ENS _ens, bytes32 _baseNode, string memory _baseNodeString) ERC721("Photochromic Identity", "PCI") {
        ens = _ens;
        baseNode = _baseNode;
        baseNodeString = _baseNodeString;
    }

    function isBaseNode(bytes32 node) external view returns (bool) {
        return node == baseNode;
    }

    function burn(bytes32 labelHash, bytes32 baseNodeUser) external onlyController {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(baseNodeUser, labelHash)));
        _burn(tokenId);
        delete hashes[tokenId];
        if (baseNodeUser == baseNode) {
            ens.setSubnodeRecord(baseNode, labelHash, address(this), address(0), 0);
        }
    }

    function nodeOwnedBy(bytes32 node, address holder) external view returns (bool) {
        return nodes[holder] == node;
    }

    function getNode(address holder) external view returns (bytes32) {
        return nodes[holder];
    }

    function removeNode(address holder) external onlyController {
        delete nodes[holder];
    }

    // Returns true if the specified name is available for registration.
    function available(uint256 namehash) public view returns (bool) {
        return !_exists(namehash);
    }

    function isUserIdAvailable(uint256 labelHash) external view returns (bool) {
        uint256 nh = uint256(keccak256(abi.encodePacked(baseNode, bytes32(labelHash))));
        return available(nh);
    }

    function register(
        address user,
        address resolver,
        bytes32 labelHash,
        bytes32 userBaseNode,
        bytes32 ipfsHash
    ) external onlyController returns (uint256) {
        require(balanceOf(user) == 0, "already has a photochromic identity");
        uint256 tokenId = uint256(keccak256(abi.encodePacked(userBaseNode, labelHash)));
        require(available(tokenId), "name already has a photochromic identity");
        _safeMint(user, tokenId);
        if (userBaseNode == baseNode) {
            ens.setSubnodeRecord(baseNode, labelHash, user, resolver, 0);
        }
        hashes[tokenId] = ipfsHash;
        nodes[user] = bytes32(tokenId);
        return tokenId;
    }

    // Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory ipfsHash = PhotochromicTools.ipfsToString(hashes[tokenId]);
        return string(abi.encodePacked("ipfs://", ipfsHash));
    }

    function _transfer(address, address, uint256) internal pure override(ERC721) {
        revert("transfer is not allowed for this token");
    }
}
