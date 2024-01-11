// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "./OwnableUpgradeable.sol";
import "./EnumerableSet.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IMNFTCurrencyManager.sol";

contract MNFTCurrencyManager is OwnableUpgradeable, AccessControlEnumerableUpgradeable, IMNFTCurrencyManager {
   using EnumerableSet for EnumerableSet.AddressSet;

   EnumerableSet.AddressSet private whitelistedCurrencies;
   mapping(address => address[]) private userWhitelistedCurrencies;
   bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

   function initialize() public initializer {
      __Ownable_init();
      _setupRole(OWNER_ROLE, msg.sender);
   }

   function addOwner(address owner_) external override onlyOwner {
      _setupRole(OWNER_ROLE, owner_);
   }

   function addCurrency(address currency) external override {
      require(!whitelistedCurrencies.contains(currency), "Currency: Already whitelisted");
      whitelistedCurrencies.add(currency);
   }

   function addUserCurrency(
      address currency,
      address user
   ) external override onlyRole(OWNER_ROLE) {
      require(!whitelistedCurrencies.contains(currency), "Currency: Already whitelisted");
      whitelistedCurrencies.add(currency);
      userWhitelistedCurrencies[user].push(currency);
   }

   function isCurrencyWhitelisted(address currency) external view override returns (bool) {
      return whitelistedCurrencies.contains(currency);
   }

   function isUserCurrencyWhitelisted(address currency, address user) external view override returns (bool) {
      uint256 length = userWhitelistedCurrencies[user].length;
      if (length > 0) {
         for (uint256 i = 0; i < length; i ++) {
           if (userWhitelistedCurrencies[user][i] == currency) {
               return true;
            }
         }
      }

      return false;
   }

   function viewUserWhitelistedCurrencies(
      address user
   ) external view override returns (address[] memory)
   {
      return userWhitelistedCurrencies[user];
   }

   function viewWhiteListedCurrencies() external view override returns(address[] memory) {
      uint256 length = whitelistedCurrencies.length();
      address[] memory currencies = new address[](length);

      if (length == 0) {
         return currencies;
      }

      for (uint256 i = 0; i < length; i++) {
         currencies[i] = whitelistedCurrencies.at(i);
      }

      return currencies;
   }
}