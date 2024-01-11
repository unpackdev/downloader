// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ContractRegistryAccess.sol";
import "./ACLAuth.sol";
import "./IACLRegistry.sol";
import "./IContractRegistry.sol";
import "./IBatchStorage.sol";
import "./Initializable.sol";

abstract contract AbstractClientAccess is ACLAuth, Initializable, ContractRegistryAccess, IClientBatchStorageAccess {
  // keccak("UPDATE_BATCH_STORAGE_CLIENT_ACTION")
  bytes32 constant UPDATE_BATCH_STORAGE_CLIENT_ACTION =
    0xb6f070e601e3563e164a63cf18567d22a74f31de2ff3f805afb7fa0c4d982e9c;

  constructor(IContractRegistry __contractRegistry, address _client) ContractRegistryAccess(__contractRegistry) {
    addClient(_client == address(0) ? msg.sender : _client);
    initialized = true;
  }

  /**
   * @dev  a mapping is made here when a client contract grants access to their batches to another client
   * owner => delegate => bool
   */
  mapping(address => mapping(address => bool)) public delegates;

  /**
   * @dev pendingClientAccessGrants contains mapping of current client to delegated clients that may accept a transfer after the given timestamp
   * client => newClient => validTransferAfter_timestamp
   */
  mapping(address => mapping(address => uint256)) public pendingClientAccessGrants;

  /**
   * @dev clients are allowed to use the batch storage contract. we allow many clients to use the batch contract. however, all batches are owned by the client which created the batch. clients have the ability to make claims / withdrawals and transfer tokens on behalf of depositors.
   */
  mapping(address => bool) public clients;

  function grantClientAccess(address newClient) external override onlyClients {
    pendingClientAccessGrants[msg.sender][newClient] = block.timestamp + 2 days;
  }

  function revokeClientAccess(address client) external override onlyClients {
    if (delegates[msg.sender][client]) {
      delegates[msg.sender][client] = false;
      clients[client] = false;
    }
  }

  function acceptClientAccess(address grantingAddress) external override {
    uint256 transferValidFrom = pendingClientAccessGrants[grantingAddress][msg.sender];
    require(transferValidFrom > 0 && transferValidFrom < block.timestamp, "access not valid");
    delegates[grantingAddress][msg.sender] = true;
    clients[msg.sender] = true;
  }

  /**
   * @notice DAO role can add any client. This is used to allow clients to use the batch storage contract.
   */
  function addClient(address _address) public override {
    bool hasPermission = acl().hasRole(DAO_ROLE, msg.sender) ||
      acl().hasPermission(UPDATE_BATCH_STORAGE_CLIENT_ACTION, msg.sender);
    if (!initialized || hasPermission) {
      clients[_address] = true;
    }
  }

  /**
   * @notice DAO role can remove any client. This is used to remove clients that are no longer using the batch storage contract. A client may remove itself by calling this function.
   */
  function removeClient(address _address) public override {
    bool hasPermission = acl().hasRole(DAO_ROLE, msg.sender) ||
      acl().hasPermission(UPDATE_BATCH_STORAGE_CLIENT_ACTION, msg.sender);
    if (hasPermission || (clients[msg.sender] && _address == msg.sender)) {
      clients[_address] = false;
    }
  }

  function acl() internal view returns (IACLRegistry) {
    return IACLRegistry(_getContract(keccak256("ACLRegistry")));
  }

  function _getContract(bytes32 _name)
    internal
    view
    virtual
    override(ACLAuth, ContractRegistryAccess)
    returns (address)
  {
    return IContractRegistry(_contractRegistry).getContract(_name);
  }

  modifier onlyClients() {
    _onlyClients();
    _;
  }

  function _onlyClients() internal view {
    require(clients[msg.sender], "!allowed");
  }
}
