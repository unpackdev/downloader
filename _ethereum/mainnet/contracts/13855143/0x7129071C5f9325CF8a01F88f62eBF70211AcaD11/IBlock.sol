//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";

interface IBlock is IERC20Upgradeable {
  function burnFrom(address account, uint256 amount) external;

  function claim(
    address to,
    uint256 amount,
    uint256 startBlockNumber,
    uint256 endBlockNumber,
    bytes calldata signature
  ) external;
}
