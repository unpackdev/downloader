// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IRiddleKeyVault {
  function initialize() external;
  function setSellEvent(uint sellPeriod, uint timeDelay) external;
  function levelOf(uint tokenId) external view returns (uint);
  function currentSupplyOf(uint level) external view returns (uint);
  function tokenOf(uint32 level) external view returns (uint32);
  function tranferKey(address to, uint tokenId, uint amount) external;
  function buyKey(address to, uint tokenId, uint amount, uint providedETH) external;
}
