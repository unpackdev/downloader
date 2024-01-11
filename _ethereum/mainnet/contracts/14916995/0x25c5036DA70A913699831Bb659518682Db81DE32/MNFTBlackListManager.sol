// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IMNFTBlackListManager.sol";

contract MNFTBlackListManager is OwnableUpgradeable, AccessControlEnumerableUpgradeable, IMNFTBlackListManager {
   using EnumerableSet for EnumerableSet.AddressSet;

   EnumerableSet.AddressSet private blacklistedUsers;
   bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

   function initialize() public initializer {
      __Ownable_init();
      _setupRole(OWNER_ROLE, msg.sender);
   }

   function addOwner(address owner_) external onlyOwner override {
      _setupRole(OWNER_ROLE, owner_);
   }

   function addToBlackList(address user_) external onlyRole(OWNER_ROLE) override {
      require(!blacklistedUsers.contains(user_), "BlackList: Already blacklisted");
      blacklistedUsers.add(user_);
   }

   function removeFromBlackList(address user_) external onlyRole(OWNER_ROLE) override {
      require(blacklistedUsers.contains(user_), "BlackList: Not blacklisted");
      blacklistedUsers.remove(user_);
   }

   function isBlackListed(address user_) external view override returns (bool) {
      return blacklistedUsers.contains(user_);
   }

   function viewBlackListedUsers() external view override returns (address[] memory) {
      uint256 length = blacklistedUsers.length();
      address[] memory users = new address[](length);

      for (uint256 i = 0; i < length; i++) {
         users[i] = blacklistedUsers.at(i);
      }

      return users;
   }
}