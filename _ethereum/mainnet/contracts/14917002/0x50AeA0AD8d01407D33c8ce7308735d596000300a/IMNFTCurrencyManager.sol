// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IMNFTCurrencyManager {
   function addOwner(address owner) external;

   function addCurrency(address currency) external;

   function addUserCurrency(address currency, address owner) external;

   function isCurrencyWhitelisted(address currency) external view returns (bool);

   function isUserCurrencyWhitelisted(address currency, address user) external view returns (bool);

   function viewUserWhitelistedCurrencies(address user) external view returns(address[] memory);

   function viewWhiteListedCurrencies() external view returns(address[] memory);
}