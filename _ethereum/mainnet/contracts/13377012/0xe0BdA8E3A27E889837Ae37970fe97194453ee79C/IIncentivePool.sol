// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./DataStruct.sol";

interface IIncentivePool {
  event ClaimIncentive(address indexed user, uint256 claimedIncentive, uint256 userIncentiveIndex);

  event UpdateIncentivePool(address indexed user, uint256 accruedIncentive, uint256 incentiveIndex);

  event IncentivePoolEnded();

  function initializeIncentivePool(address lToken) external;

  function updateIncentivePool(address user) external;

  function beforeTokenTransfer(address from, address to) external;

  function claimIncentive() external;

  function withdrawResidue() external;
}
