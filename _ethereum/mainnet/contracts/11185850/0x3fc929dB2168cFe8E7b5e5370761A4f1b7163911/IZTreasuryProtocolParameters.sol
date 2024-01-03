// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "./IERC20.sol";

interface zGovernance {
  function notifyRewardAmount(uint) external;
}

interface IZTreasuryProtocolParameters {
  event ZGovSet(address zGov);
  event MaintainerSet(address maintainer);
  event ZTokenSet(address zToken);
  event SharesSet(uint256 maintainerShare, uint256 governanceShare);

  function zToken() external returns (IERC20); // zhegic

  function zGov() external returns (zGovernance); // zgov rewards
  function maintainer() external returns (address);

  function SHARES_PRECISION() external returns (uint256);
  function MAX_MAINTAINER_SHARE() external returns (uint256);
  function maintainerShare() external returns (uint256);
  function governanceShare() external returns (uint256);

  function setZGov(address _zGov) external;
  function setMaintainer(address _maintainer) external;
  function setZToken(address _zToken) external;
  function setShares(uint256 _maintainerShare, uint256 _governanceShare) external;
}