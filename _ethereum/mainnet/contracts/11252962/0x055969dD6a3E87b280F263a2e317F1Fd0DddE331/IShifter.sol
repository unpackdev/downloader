// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IShifter {
  function mint(bytes32 _pHash, uint256 _amount, bytes32 _nHash, bytes calldata _sig) external returns (uint256);
  function mintFee() external view returns (uint256);
}
