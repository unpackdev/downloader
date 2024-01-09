// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBadgerSettPeak {
  function mint(
    uint256 poolId,
    uint256 inAmount,
    bytes32[] calldata merkleProof
  ) external returns (uint256 outAmount);

  function approveContractAccess(address account) external;

  function owner() external view returns (address _owner);

  function redeem(uint256 poolId, uint256 inAmount)
    external
    returns (uint256 outAmount);

  function calcMint(uint256 poolId, uint256 inAmount)
    external
    view
    returns (uint256 bBTC, uint256 fee);

  function calcRedeem(uint256 poolId, uint256 bBtc)
    external
    view
    returns (
      uint256 sett,
      uint256 fee,
      uint256 max
    );
}
