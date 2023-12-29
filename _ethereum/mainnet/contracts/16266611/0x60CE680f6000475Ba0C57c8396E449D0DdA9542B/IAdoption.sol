// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./Type.sol";

interface IAdoption {
  function availableNodeCapOf(
    uint256 tier_
  ) external view returns (uint256);

  function getSalesInfo(
  ) external view returns (SalesInfo memory);

  function isWhitelisted(
    address userAddress
  ) external view returns (bool);

  function purchase(
    uint256 tier_
  ) external payable returns (uint256);

  function updatePrice(
    uint256 tier_,
    uint256 price_
  ) external;

  function addToWhitelist(
    address[] memory addresses_
  ) external;

  function setDiscountInfo(
    uint256 startTimestamp_,
    uint256 endTimestamp_,
    uint256 discountRate_
  ) external;

  function removeDiscountInfo(
  ) external;

  function destroy(
    address payable to_
  ) external;
}