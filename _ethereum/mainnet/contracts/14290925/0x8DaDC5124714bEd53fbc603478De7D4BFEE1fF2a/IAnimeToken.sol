// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IAnimeToken {
  function MINTER_ROLE() external returns (bytes32);

  function mint(address _account, uint256 _amount) external;
}
