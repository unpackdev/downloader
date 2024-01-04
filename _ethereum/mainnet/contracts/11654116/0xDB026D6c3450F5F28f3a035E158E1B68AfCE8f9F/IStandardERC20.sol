// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;
import "./IERC20.sol";

interface IStandardERC20 is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}
