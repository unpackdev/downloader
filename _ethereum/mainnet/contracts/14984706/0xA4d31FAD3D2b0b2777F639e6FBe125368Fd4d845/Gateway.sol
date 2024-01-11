// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./IGateway.sol";

/**
 * @title Gateway Contract (Single Relayer / Validator version)
 */

contract Gateway is ReentrancyGuard, IGateway {
    using Address for address;

    enum Role {
        UNAUTHORIZED,
        ADMIN,
        RELAYER,
        VALIDATOR
    }

    struct RelayMessage {
        bytes32 root;
        uint256 timestamp;
    }

    struct ClaimMessage {
        bytes32 root;
        uint256 timestamp;
    }

    // ACL
    mapping(address => Role) private permissions;
    // Chain ID
    uint256 public override chainId;
    // Each message contains Merkle Tree's root of all orders listed from all EVM chains
    mapping(uint256 => RelayMessage) public relayMessages;
    uint256 public relayMessageCount;
    // Clearance messages contains the hash
    mapping(uint256 => ClaimMessage) public claimMessages;
    uint256 public claimMessageCount;

    constructor(address _devAddress, uint256 _chainId) public {
        permissions[_devAddress] = Role.ADMIN;

        if (_devAddress != msg.sender) {
            permissions[msg.sender] = Role.ADMIN;
        }

        chainId = _chainId;
    }

    // return latest confirmation's state root
    function claimRoot() external view override returns (bytes32) {
        return claimMessages[claimMessageCount].root;
    }

    // return latest relay's state root
    function relayRoot() external view override returns (bytes32) {
        return relayMessages[relayMessageCount].root;
    }

    // attach all orders in Merkle's root
    function updateRelayMessage(bytes32 _root)
        external
        onlyRelayer
        nonReentrant
    {
        relayMessageCount += 1;
        relayMessages[relayMessageCount].root = _root;
        relayMessages[relayMessageCount].timestamp = now;
    }

    // attach all approvals in Merkle's root
    function updateClaimMessage(bytes32 _root)
        external
        onlyValidator
        nonReentrant
    {
        claimMessageCount += 1;
        claimMessages[claimMessageCount].root = _root;
        claimMessages[claimMessageCount].timestamp = now;
    }

    // give a specific permission to the given address
    function grant(address _address, Role _role) external onlyAdmin {
        require(_address != msg.sender, "You cannot grant yourself");
        permissions[_address] = _role;
    }

    // remove any permission binded to the given address
    function revoke(address _address) external onlyAdmin {
        require(_address != msg.sender, "You cannot revoke yourself");
        permissions[_address] = Role.UNAUTHORIZED;
    }

    // INTERNAL FUNCTIONS

    modifier onlyAdmin() {
        require(
            permissions[msg.sender] == Role.ADMIN,
            "Caller is not the admin"
        );
        _;
    }

    modifier onlyRelayer() {
        require(
            permissions[msg.sender] == Role.RELAYER,
            "Caller is not the relayer"
        );
        _;
    }

    modifier onlyValidator() {
        require(
            permissions[msg.sender] == Role.VALIDATOR,
            "Caller is not the validator"
        );
        _;
    }
}
