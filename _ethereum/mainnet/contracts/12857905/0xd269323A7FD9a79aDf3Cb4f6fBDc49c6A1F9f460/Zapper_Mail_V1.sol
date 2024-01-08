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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
}

contract Zapper_Mail_V1 is SignatureVerifier {
    EnsRegistry public registry;
    EnsResolver public resolver;
    bytes32 public baseNode;
    bool public paused = false;
    mapping(address => bytes32) public addressToNode;

    event UserRegistered(
        bytes32 indexed baseNode,
        bytes32 indexed usernameHash,
        address indexed addr,
        string username,
        string publicKey
    );
    event UserUnregistered(
        bytes32 indexed baseNode,
        bytes32 indexed usernameHash,
        address indexed addr,
        string username
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
     * @dev Transfer ownership of any domain or subdomain owned by this address
     * @param _node - namehash of the domain or subdomain to transfer
     * @param _owner - new owner for the ENS domain
     */
    function transferDomainOwnership(bytes32 _node, address _owner)
        external
        onlyOwner
    {
        registry.setOwner(_node, _owner);
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
     * @param _username - Username being requested
     * @param _publicKey - The Zapper mail encryption public key for this username
     * @param _signature - Verified signature granting account the subdomain
     */
    function registerUser(
        string calldata _username,
        string calldata _publicKey,
        bytes calldata _signature
    ) external pausable {
        bytes32 _node = node(_username);

        // Confirm that the signature matches that of the sender
        require(
            verifyAccountAndPublicKeyPair(msg.sender, _publicKey, _signature),
            "Err: Invalid Signature"
        );

        // Require that the subdomain is not already owned or owned by the previous implementation (migration)
        require(
            resolver.addr(_node) == address(0) ||
                resolver.addr(_node) == address(this) ||
                resolver.addr(_node) == msg.sender, // For migrations from previous contract deployments
            "Err: Subdomain already assigned"
        );

        // Require that the account does not already own a subdomain
        require(
            addressToNode[msg.sender] == "",
            "Err: Account already owns a subdomain"
        );

        // Take ownership of the subdomain and configure it
        bytes32 usernameHash = keccak256(bytes(_username));
        registry.setSubnodeOwner(baseNode, usernameHash, address(this));
        registry.setResolver(_node, address(resolver));
        resolver.setAddr(_node, msg.sender);
        registry.setOwner(_node, address(this));

        // Keep track of the associated node per account
        addressToNode[msg.sender] = _node;

        // Emit event to index registration on the backend
        emit UserRegistered(
            baseNode,
            usernameHash,
            msg.sender,
            _username,
            _publicKey
        );
    }

    function setUserData(
        string calldata _username,
        string calldata _key,
        string calldata _value,
        bytes calldata _signature
    ) external pausable {
        bytes32 _node = node(_username);

        // Confirm that the signature matches that of the sender
        require(
            verifyUserDataPair(msg.sender, _key, _value, _signature),
            "Err: Invalid Signature"
        );

        // Require that the subdomain is owned by this account
        require(
            _node == addressToNode[msg.sender] &&
                resolver.addr(_node) == msg.sender,
            "Err: Subdomain not assigned to account"
        );

        resolver.setText(_node, _key, _value);
    }

    function unregisterUser(string calldata _username) external pausable {
        bytes32 _node = node(_username);

        // Require that the subdomain is owned by this account
        require(
            _node == addressToNode[msg.sender] &&
                resolver.addr(_node) == msg.sender,
            "Err: Subdomain not assigned to account"
        );

        // Take ownership of the subdomain and configure it
        bytes32 usernameHash = keccak256(bytes(_username));
        registry.setSubnodeOwner(baseNode, usernameHash, address(this));
        resolver.setAddr(_node, address(0));
        registry.setOwner(_node, address(this));

        // Keep track of the associated node per account
        addressToNode[tx.origin] = "";

        // Emit event to index revocation on the backend
        emit UserUnregistered(baseNode, usernameHash, msg.sender, _username);
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

    /**
     * @dev Emergency withdraw if anyone sends funds to this address
     * @param _tokens - Addresses of the tokens (or ETH as zero address) to withdraw
     */
    function withdrawTokens(address[] calldata _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                payable(owner()).transfer(address(this).balance);
            } else {
                uint256 qty = IERC20(_tokens[i]).balanceOf(address(this));
                IERC20(_tokens[i]).transfer(owner(), qty);
            }
        }
    }
}
