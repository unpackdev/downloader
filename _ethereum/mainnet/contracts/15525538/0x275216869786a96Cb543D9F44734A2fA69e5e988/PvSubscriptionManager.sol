// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./AccessControl.sol";

contract PvSubscriptionManager is AccessControl {
  VRFCoordinatorV2Interface immutable COORDINATOR;
  LinkTokenInterface immutable LINKTOKEN;

  uint64 public s_subscriptionId;

  bytes32 public constant USER_ROLE = keccak256("USER_ROLE");

  error NoActiveSubscription();

  constructor(
    address _vrfCoordinator,
    address _linkToken,
    address _superAdmin
  ) {

    COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(_linkToken);
    
    s_subscriptionId = COORDINATOR.createSubscription();

    _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
    _setupRole(USER_ROLE, _msgSender());    
  }

  function topUpSubscription(uint256 amount) external onlyRole(USER_ROLE) {
    if(s_subscriptionId == 0) {
      revert NoActiveSubscription();
    }

    LINKTOKEN.transferAndCall(address(COORDINATOR), amount, abi.encode(s_subscriptionId));
  }

  function addConsumer(address consumerAddress) external onlyRole(USER_ROLE) {
    if(s_subscriptionId == 0) {
      revert NoActiveSubscription();
    }

    COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
  }

  function removeConsumer(address consumerAddress) external onlyRole(USER_ROLE) {
    if(s_subscriptionId == 0) {
      revert NoActiveSubscription();
    }

    COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
  }

  function createNewSubscription() external onlyRole(USER_ROLE) returns (uint64) {
    s_subscriptionId = COORDINATOR.createSubscription();

    return s_subscriptionId;
  }

  function cancelSubscription(address receivingWallet) external onlyRole(USER_ROLE) {
    if(s_subscriptionId == 0) {
      revert NoActiveSubscription();
    }

    COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
    s_subscriptionId = 0;
  }

  function withdraw(uint256 amount, address to) external onlyRole(USER_ROLE) {
    LINKTOKEN.transfer(to, amount);
  }

  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external onlyRole(USER_ROLE) {
    COORDINATOR.requestSubscriptionOwnerTransfer(subId, newOwner);
  }

  function acceptSubscriptionOwnerTransfer(uint64 subId) external onlyRole(USER_ROLE) {
    COORDINATOR.acceptSubscriptionOwnerTransfer(subId);
    s_subscriptionId = subId; 
  }

  function getSubscription() external view returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
  ) {
      return COORDINATOR.getSubscription(s_subscriptionId);
  }
}

