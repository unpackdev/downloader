// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./IMNFT1155.sol";
import "./IMNFT721.sol";
import "./IMNFTRoyaltyManager.sol";
import "./console.sol";

contract MNFTRoyaltyManager is OwnableUpgradeable, AccessControlEnumerableUpgradeable, IMNFTRoyaltyManager {
   uint16 private ROYALTY_MIN;     // over 1e3, 500 means 0.5%
   uint16 private ROYALTY_MAX;     // over 1e3, 10000 means 10%
   uint16 private globalRoyalty;   // over 1e3, 500 means 0.5%
   bytes32 private OWNER_ROLE;
   // ERC721 interfaceID
   bytes4 public INTERFACE_ID_ERC721;
   // ERC1155 interfaceID
   bytes4 public INTERFACE_ID_ERC1155;

   address private marketplaceAddress;
   mapping(address => RoyaltyInfo) private royaltyInfos;

   struct RoyaltyInfo {
      address receiver;
      uint16 rate;
   }

   function initialize() public initializer {
      __Ownable_init();
      OWNER_ROLE = keccak256("OWNER_ROLE");
      INTERFACE_ID_ERC721 = 0x80ac58cd;
      INTERFACE_ID_ERC1155 = 0xd9b67a26;
      ROYALTY_MIN = 5 * 1e2;
      ROYALTY_MAX = 1 * 1e4;
      globalRoyalty = 2 * 1e3;   // 2%
      _setupRole(OWNER_ROLE, msg.sender);
   }

   function addOwner(address newOwner_) external onlyOwner {
      _setupRole(OWNER_ROLE, newOwner_);
   }

   function setBasicData(address marketplaceAddress_) external onlyOwner {
      marketplaceAddress = marketplaceAddress_;
   }

   function updateGlobalRoyalty(
      uint16 royalty_
   ) external onlyRole(OWNER_ROLE) override {
      _validateRoyalty(royalty_);
      globalRoyalty = royalty_;
   }

   function setUserRoyalty(
      address setter_,
      address tokenAddress_,
      uint16 royalty_
   ) external onlyRole(OWNER_ROLE) override {
      _validateRoyalty(royalty_);
      require (setter_ != address(0), 'wrong setter');
      require (tokenAddress_ != address(0), 'wrong token address');
      require (_getOwner(tokenAddress_) == setter_, 'not owner');
      royaltyInfos[tokenAddress_] = RoyaltyInfo({
         receiver: setter_,
         rate: royalty_
      });
   }

   function getRoyaltyFee(
      address tokenAddress_,
      uint256 amount_
   ) external view override returns(
      address receiver,
      uint256 globalFee, 
      uint256 userFee
   ) {
      if (amount_ == 0) {
         globalFee = userFee = 0;
      }

      globalFee = amount_ * uint256(globalRoyalty) / 1e5;
      if (royaltyInfos[tokenAddress_].rate > 0) {
         userFee = amount_ * uint256(royaltyInfos[tokenAddress_].rate) / 1e5;
         receiver = royaltyInfos[tokenAddress_].receiver;
      } else {
         userFee = 0;
      }
   }

   function _validateRoyalty(uint16 royalty_) internal view {
      require (royalty_ >= ROYALTY_MIN && royalty_ <= ROYALTY_MAX, 'not proper rate');
   }

   function _getOwner(address tokenAddress_) internal view returns(address) {
      if (IERC165Upgradeable(tokenAddress_).supportsInterface(INTERFACE_ID_ERC721)) {
         return IMNFT721(tokenAddress_).owner();
      } else if (IERC165Upgradeable(tokenAddress_).supportsInterface(INTERFACE_ID_ERC1155)) {
         return IMNFT1155(tokenAddress_).owner();
      }

      return address(0);
   }

}