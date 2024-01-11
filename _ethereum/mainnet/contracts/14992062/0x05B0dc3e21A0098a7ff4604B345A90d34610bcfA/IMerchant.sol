// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Types.sol";

interface IMerchant {
  function availableWhitelistCapOf(address user_, uint256 tier_) external view returns (uint256);

  function availableCapOf(address user_) external view returns (uint256);

  function getSalesInfo() external view returns (SalesInfo memory);

  function setPublicSaleEnd(uint256 time_) external;

  function destroy(address payable to_) external;

  function reserve(ReservePayload[] memory payload_) external;

  function purchase(uint256 amount_, uint256 tier_) external payable returns (uint256[] memory);
}
