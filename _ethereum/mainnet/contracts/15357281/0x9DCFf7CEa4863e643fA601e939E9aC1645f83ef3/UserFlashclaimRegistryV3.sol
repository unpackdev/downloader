// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ClonesUpgradeable.sol";

import "./UserFlashclaimRegistry.sol";
import "./UserFlashclaimRegistryV2.sol";
import "./AirdropFlashLoanReceiverV3.sol";

contract UserFlashclaimRegistryV3 {
  using ClonesUpgradeable for address;

  address public immutable bnftRegistry;
  mapping(address => address) public userReceiversV3;
  address public immutable receiverV3Implemention;
  address public immutable flashClaimRegistryV2;
  uint256 public constant VERSION = 3;

  constructor(address bnftRegistry_, address flashClaimRegistryV2_) {
    bnftRegistry = bnftRegistry_;
    flashClaimRegistryV2 = flashClaimRegistryV2_;
    receiverV3Implemention = address(new AirdropFlashLoanReceiverV3());
  }

  function createReceiver() public {
    address userReceiverV2 = UserFlashclaimRegistryV2(flashClaimRegistryV2).userReceivers(msg.sender);
    require(userReceiverV2 == address(0), "user already has a old version receiver");

    require(userReceiversV3[msg.sender] == address(0), "user already has a V3 receiver");
    _createReceiver();
  }

  function forceCreateReceiver() public {
    require(userReceiversV3[msg.sender] == address(0), "user already has a V3 receiver");
    _createReceiver();
  }

  function _createReceiver() internal {
    address receiverV3 = receiverV3Implemention.clone();
    AirdropFlashLoanReceiverV3(receiverV3).initialize(msg.sender, bnftRegistry, 1);

    userReceiversV3[msg.sender] = address(receiverV3);
  }

  function userReceivers(address user) public view returns (address) {
    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      return receiverV3;
    }

    return UserFlashclaimRegistryV2(flashClaimRegistryV2).userReceivers(user);
  }

  function getUserReceiverLatestVersion(address user) public view returns (uint256, address) {
    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      return (3, receiverV3);
    }

    address receiverV2 = UserFlashclaimRegistryV2(flashClaimRegistryV2).userReceiversV2(user);
    if (receiverV2 != address(0)) {
      return (2, receiverV2);
    }

    address claimRegistryV1 = UserFlashclaimRegistryV2(flashClaimRegistryV2).flashClaimRegistryV1();
    address receiverV1 = UserFlashclaimRegistry(claimRegistryV1).userReceivers(user);
    if (receiverV1 != address(0)) {
      return (1, receiverV1);
    }

    return (0, address(0));
  }

  function getUserReceiverAllVersions(address user) public view returns (uint256[] memory, address[] memory) {
    uint256 length;
    uint256[3] memory versions;
    address[3] memory addresses;

    address receiverV3 = userReceiversV3[user];
    if (receiverV3 != address(0)) {
      versions[length] = 3;
      addresses[length] = receiverV3;
      length++;
    }

    address receiverV2 = UserFlashclaimRegistryV2(flashClaimRegistryV2).userReceiversV2(user);
    if (receiverV2 != address(0)) {
      versions[length] = 2;
      addresses[length] = receiverV2;
      length++;
    }

    address claimRegistryV1 = UserFlashclaimRegistryV2(flashClaimRegistryV2).flashClaimRegistryV1();
    address receiverV1 = UserFlashclaimRegistry(claimRegistryV1).userReceivers(user);
    if (receiverV1 != address(0)) {
      versions[length] = 1;
      addresses[length] = receiverV1;
      length++;
    }

    uint256[] memory retVersions = new uint256[](length);
    address[] memory retAddresses = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      retVersions[i] = versions[i];
      retAddresses[i] = addresses[i];
    }

    return (retVersions, retAddresses);
  }
}
