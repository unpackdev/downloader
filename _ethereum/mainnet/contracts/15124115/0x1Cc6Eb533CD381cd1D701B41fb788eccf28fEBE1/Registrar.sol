// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./ENS.sol";
import "./Owned.sol";

import "./IAuthoriser.sol";
import "./IRulesEngine.sol";
import "./Utils.sol";

/// @title Subdomain Registrar Interface
/// @author charchar.eth
/// @notice Define the minimum methods needed for a subdomain registrar
interface IRegistrar {
    /// @notice Register a subdomain under node
    /// @param node The project node to use
    /// @param label The subdomain text, eg the 'hopeless' in hopeless.abc.eth
    /// @param authData Additional data to help the authoriser authorise
    function register(
        bytes32 node,
        string memory label,
        bytes memory authData
    ) external;

    /// @notice Check if a label is valid for a project
    /// @param node The project node
    /// @param label The subdomain label to validate
    /// @return True if the label is valid, according to the project rules, false otherwise
    function valid(bytes32 node, string memory label)
        external
        view
        returns (bool);

    /// @notice Register a project as a subdomain provider
    /// @param node The fully qualified, namehashed ENS name
    /// @param authoriser The contract that will perform authorisation
    /// @param rules The contract that will provide rules and validation
    /// @param enable Allow project auth and rules to run
    function setProjectNode(
        bytes32 node,
        IAuthoriser authoriser,
        IRulesEngine rules,
        bool enable
    ) external;
}

/// @title me3 Subdomain Registrar
/// @author charchar.eth
/// @notice Provides third-party projects with a common subdomain registration function
/// @dev 0.1.0
contract Registrar is IRegistrar, Owned(msg.sender) {
    ENS public ens;

    /// @notice Lookup enabled/disabled state by project node
    mapping(bytes32 => bool) public nodeEnabled;

    /// @notice Lookup authoriser contract by project node
    mapping(bytes32 => IAuthoriser) public nodeAuthorisers;

    /// @notice Lookup rules contract by project node
    mapping(bytes32 => IRulesEngine) public nodeRules;

    /// @notice A project has been enabled/disabled
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param authoriser The address of the authorising contract
    /// @param rules The address of the rules engine contract
    /// @param enabled True if the project is now enabled, false if now disabled
    event ProjectStateChanged(
        bytes32 indexed node,
        address authoriser,
        address rules,
        bool enabled
    );

    /// @notice A subnode has been registered
    /// @param node The fully qualified, namehashed ENS name for the project
    /// @param label The registered label as keccack256
    /// @param owner The registered owner
    /// @param registrant The address that requested registration
    event SubnodeRegistered(
        bytes32 indexed node,
        bytes32 indexed label,
        address owner,
        address registrant
    );

    modifier isAuthorised(
        bytes32 node,
        address user,
        bytes memory authData
    ) {
        IAuthoriser authoriser = nodeAuthorisers[node];

        require(authoriser.canRegister(node, user, authData), "User is not authorised");
        _;
    }

    modifier registeredNode(bytes32 node) {
        require(nodeEnabled[node], "Node is not enabled");
        _;
    }

    constructor(ENS _registry) {
        ens = _registry;
    }

    /// @notice Add a new project to the directory
    /// @param node The project node that subdomains will be based on
    /// @param authoriser The authorisation contract
    /// @param rules The rules around availability, validity, and usage
    /// @param enable Turn the project on or off
    function setProjectNode(
        bytes32 node,
        IAuthoriser authoriser,
        IRulesEngine rules,
        bool enable
    ) external onlyOwner {
        emit ProjectStateChanged(node, address(authoriser), address(rules), enable);

        nodeAuthorisers[node] = authoriser;
        nodeRules[node] = rules;
        nodeEnabled[node] = enable;
    }

    /// @inheritdoc IRegistrar
    function register(
        bytes32 node,
        string memory label,
        bytes memory authData
    ) external registeredNode(node) isAuthorised(node, msg.sender, authData) {
        require(valid(node, label), "Check with project for valid subdomain requirements");
        require(available(node, label), "Label must be available to register");

        bytes32 hashedLabel = Utilities.labelhash(label);
        address owner = nodeRules[node].subnodeOwner(msg.sender);
        address resolver = nodeRules[node].profileResolver(node, label, msg.sender);
        require(resolver != address(0x0), "Resolver must be set by project");

        emit SubnodeRegistered(node, hashedLabel, owner, msg.sender);
        ens.setSubnodeRecord(node, hashedLabel, owner, resolver, 86400);
    }

    /// @inheritdoc IRegistrar
    function valid(bytes32 node, string memory label)
        public
        view
        registeredNode(node)
        returns (bool)
    {
        return nodeRules[node].isLabelValid(node, label);
    }

    function available(bytes32 node, string memory label)
        internal
        view
        returns (bool)
    {
        bytes32 fullNode = Utilities.namehash(node, Utilities.labelhash(label));
        return ens.owner(fullNode) == address(0x0);
    }

    /**
      No fallback or receive functions are implemented on purpose
      */
}
