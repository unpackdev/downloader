// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IRiddleBrainVault {
  function countOf(uint batchNum) external view returns (uint32);
  function discountOf(uint batchNum) external view returns (uint32);
  function getBrainPrice() external view returns (uint);
  function transferBrainsTo(address to, uint amount) external;
  function burnBrainsOf(address user, uint amount) external;
  function transferBrainBatchTo(address to, uint batchNum) external;
}
