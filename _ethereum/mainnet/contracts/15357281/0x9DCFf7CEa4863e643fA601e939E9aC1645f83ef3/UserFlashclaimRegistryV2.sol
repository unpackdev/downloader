// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ClonesUpgradeable.sol";

import "./UserFlashclaimRegistry.sol";
import "./AirdropFlashLoanReceiverV2.sol";

contract UserFlashclaimRegistryV2 {
  using ClonesUpgradeable for address;

  address public bnftRegistry;
  mapping(address => address) public userReceiversV2;
  address public immutable receiverV2Implemention;
  address public immutable flashClaimRegistryV1;

  constructor(address bnftRegistry_, address flashClaimRegistryV1_) {
    bnftRegistry = bnftRegistry_;
    flashClaimRegistryV1 = flashClaimRegistryV1_;
    receiverV2Implemention = address(new AirdropFlashLoanReceiverV2());
  }

  function createReceiver() public {
    address userReceiverV1 = UserFlashclaimRegistry(flashClaimRegistryV1).userReceivers(msg.sender);
    require(userReceiverV1 == address(0), "user already has a V1 receiver");

    require(userReceiversV2[msg.sender] == address(0), "user already has a V2 receiver");
    address receiverV2 = receiverV2Implemention.clone();
    AirdropFlashLoanReceiverV2(receiverV2).initialize(msg.sender, bnftRegistry, 1);

    userReceiversV2[msg.sender] = address(receiverV2);
  }

  function userReceivers(address user) public view returns (address) {
    address receiverV2 = userReceiversV2[user];
    if (receiverV2 != address(0)) {
      return receiverV2;
    }

    return UserFlashclaimRegistry(flashClaimRegistryV1).userReceivers(user);
  }
}
