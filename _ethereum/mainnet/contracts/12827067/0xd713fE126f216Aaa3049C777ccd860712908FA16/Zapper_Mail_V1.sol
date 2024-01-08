// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2021 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice Zapper Mail implementation with inspiration from Melon Mail.
// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Signature_Verifier.sol";
import "./ENS_Registry.sol";
import "./ENS_Resolver.sol";

contract Zapper_Mail_V1 is SignatureVerifier {
    EnsRegistry public registry;
    EnsResolver public resolver;
    bytes32 public baseNode;
    bool public paused = false;

    event UserRegistered(
        bytes32 indexed baseNode,
        bytes32 indexed usernameHash,
        address indexed addr,
        string username,
        string publicKey
    );
    event MessageSent(
        bytes32 indexed baseNode,
        address indexed from,
        address indexed to,
        string mailHash
    );
    event RegistryUpdated(address indexed registry);
    event ResolverUpdated(address indexed resolver);
    event BaseNodeUpdated(bytes32 indexed basenode);

    constructor(
        address _signer,
        EnsRegistry _registry,
        EnsResolver _resolver,
        bytes32 _baseNode
    ) SignatureVerifier(_signer) {
        registry = _registry;
        resolver = _resolver;
        baseNode = _baseNode;
    }

    modifier pausable {
        if (paused) {
            revert("Paused");
        } else {
            _;
        }
    }

    /**
     * @dev Pause or unpause the mail functionality
     */
    function pause() external onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Transfer ownership of the top ENS domain
     * @param _node - namehash of the top ENS domain
     * @param _owner - new owner for the ENS domain
     */
    function transferDomainOwnership(bytes32 _node, address _owner)
        external
        onlyOwner
    {
        registry.setOwner(_node, _owner);
    }

    /**
     * @dev Transfer resolved address of the ENS subdomain
     * @param _node - namehash of the ENS subdomain
     * @param _account - new resolved address of the ENS subdomain
     */
    function transferSubdomainAddress(bytes32 _node, address _account)
        external
    {
        require(
            registry.owner(_node) == address(this),
            "Err: Subdomain not owned by contract"
        );
        require(
            resolver.addr(_node) == tx.origin,
            "Err: Subdomain not owned by sender"
        );
        resolver.setAddr(_node, _account);
    }

    /**
     * @dev Returns the node for the subdomain specified by the username
     */
    function node(string calldata _username) public view returns (bytes32) {
        return
            keccak256(abi.encodePacked(baseNode, keccak256(bytes(_username))));
    }

    /**
     * @dev Updates to new ENS registry.
     * @param _registry The address of new ENS registry to use.
     */
    function updateRegistry(EnsRegistry _registry) external onlyOwner {
        require(registry != _registry, "Err: New registry should be different");
        registry = _registry;
        emit RegistryUpdated(address(registry));
    }

    /**
     * @dev Allows to update to new ENS resolver.
     * @param _resolver The address of new ENS resolver to use.
     */
    function updateResolver(EnsResolver _resolver) external onlyOwner {
        require(resolver != _resolver, "Err: New resolver should be different");
        resolver = _resolver;
        emit ResolverUpdated(address(resolver));
    }

    /**
     * @dev Allows to update to new ENS base node.
     * @param _baseNode The new ENS base node to use.
     */
    function updateBaseNode(bytes32 _baseNode) external onlyOwner {
        require(baseNode != _baseNode, "Err: New node should be different");
        baseNode = _baseNode;
        emit BaseNodeUpdated(baseNode);
    }

    /**
     * @dev Registers a username to an address, such that the address will own a subdomain of zappermail.eth
     * i.e.: If a user registers "joe", they will own "joe.zappermail.eth"
     * @param _account - Address of the new owner of the username
     * @param _node - Subdomain node to be registered
     * @param _username - Username being requested
     * @param _publicKey - The Zapper mail encryption public key for this username
     * @param _signature - Verified signature granting account the subdomain
     */
    function registerUser(
        address _account,
        bytes32 _node,
        string calldata _username,
        string calldata _publicKey,
        bytes calldata _signature
    ) external pausable {
        // Confirm that the signature matches that of the sender
        require(
            verify(_account, _publicKey, _signature),
            "Err: Invalid Signature"
        );

        // Validate that the node is valid for the given username
        require(
            node(_username) == _node,
            "Err: Node does not match ENS subdomain"
        );

        // Require that the subdomain is not already owned or owned by this registry
        require(
            registry.owner(_node) == address(0) ||
                registry.owner(_node) == address(this),
            "Err: Subdomain already owned"
        );

        // Take ownership of the subdomain and configure it
        bytes32 usernameHash = keccak256(bytes(_username));
        registry.setSubnodeOwner(baseNode, usernameHash, address(this));
        registry.setResolver(_node, address(resolver));
        resolver.setAddr(_node, _account);
        registry.setOwner(_node, address(this));

        // Emit event to index users on the backend
        emit UserRegistered(
            baseNode,
            usernameHash,
            _account,
            _username,
            _publicKey
        );
    }

    /**
     * @dev Sends a message to a user
     * @param _recipient - Address of the recipient of the message
     * @param _hash - IPFS hash of the message
     */
    function sendMessage(address _recipient, string calldata _hash)
        external
        pausable
    {
        emit MessageSent(baseNode, tx.origin, _recipient, _hash);
    }

    /**
     * @dev Batch sends a message to users
     * @param _recipients - Addresses of the recipients of the message
     * @param _hashes - IPFS hashes of the message
     */
    function batchSendMessage(
        address[] calldata _recipients,
        string[] calldata _hashes
    ) external pausable {
        require(
            _recipients.length == _hashes.length,
            "Err: Expected same number of recipients as hashes"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            emit MessageSent(baseNode, tx.origin, _recipients[i], _hashes[i]);
        }
    }
}
