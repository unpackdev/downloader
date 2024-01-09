// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ENS.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./CitizenENSResolver.sol";

contract CitizenENSRegistrar is Ownable {

    using Strings for uint256;

    ENS public immutable _registry;
    CitizenENSResolver public immutable _resolver;
    ERC721 public immutable _citizen;

    string public _rootName;  // citizen.eth
    bytes32 public _rootNode; // namehash(citizen.eth)

    // Mapping from token ID to subdomain label
    mapping(uint256 => bytes32) public _labels;

    event Claimed(address owner, string label);
    event Updated(address owner, string label);
    event Migrated(address newRegistrar);

    constructor(ENS registry, ERC721 citizen, string memory rootName, bytes32 rootNode) {

        _registry = registry;
        _resolver = new CitizenENSResolver(registry);
        _citizen = citizen;

        _rootName = rootName;
        _rootNode = rootNode;

    }

    function claim(uint256 tokenId, string calldata label) public {

        // Check that the caller owns the supplied tokenId.
        require(_citizen.ownerOf(tokenId) == msg.sender, "Caller must own the supplied tokenId.");

        // Check that a subdomain hasn't already been claimed for this tokenId.
        require(_labels[tokenId] == bytes32(0), "Caller has already claimed a subdomain.");

        // Encode the supplied label.
        bytes32 labelNode = keccak256(abi.encodePacked(label));
        bytes32 node = keccak256(abi.encodePacked(_rootNode, labelNode));

        // Make sure the label hasn't been claimed.
        require(_registry.owner(node) == address(0), "The supplied label has already been claimed.");

        // Create the subdomain.
        _registry.setSubnodeRecord(_rootNode, labelNode, msg.sender, address(_resolver), 0);
        _resolver.setAddr(node, msg.sender);
        _resolver.setText(node, "id.citizen", tokenId.toString());
        _labels[tokenId] = labelNode;

        // Emit an event.
        emit Claimed(msg.sender, label);

    }

    function update(uint256 tokenId, string calldata label) public {

        // Check that the caller owns the supplied tokenId.
        require(_citizen.ownerOf(tokenId) == msg.sender, "Caller must own the supplied tokenId.");

        // Check that a subdomain has already been claimed for this tokenId.
        require(_labels[tokenId] != bytes32(0), "Caller hasn't claimed a subdomain.");

        // Encode the supplied label.
        bytes32 labelNode = keccak256(abi.encodePacked(label));
        bytes32 node = keccak256(abi.encodePacked(_rootNode, labelNode));

        // Make sure the label hasn't been claimed.
        require(_registry.owner(node) == address(0), "The supplied label has already been claimed.");

        // Delete the previous subdomain, creating a new one.
        _registry.setSubnodeRecord(_rootNode, _labels[tokenId], address(0), address(0), 0);
        _resolver.setAddr(_labels[tokenId], address(0));
        _resolver.setText(_labels[tokenId], "id.citizen", "");

        _registry.setSubnodeRecord(_rootNode, labelNode, msg.sender, address(_resolver), 0);
        _resolver.setAddr(node, msg.sender);
        _resolver.setText(node, "id.citizen", tokenId.toString());

        _labels[tokenId] = labelNode;

        // Emit an event.
        emit Updated(msg.sender, label);

    }

    function transfer(uint256 tokenId, address to) public onlyCitizenNFT {

        bytes32 label = _labels[tokenId];

        // Check if a label has been claimed for this tokenId.
        if (label != bytes32(0)) {

            // If a label has been claimed ...
            // Transfer ownership of the subdomain.
            bytes32 node = keccak256(abi.encodePacked(_rootNode, label));
            _registry.setSubnodeOwner(_rootNode, label, to);
            _resolver.setAddr(node, to);

        }

    }

    function migrate(address newRegistrar) public onlyOwner {

        _registry.setOwner(_rootNode, newRegistrar);
        emit Migrated(newRegistrar);

    }

    modifier onlyCitizenNFT() {

        require(
            msg.sender == address(_citizen),
            "Caller is not the CITIZEN NFT."
        );
        _;

    }

}
