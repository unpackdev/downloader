// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20Upgradeable.sol";

interface IMETASALTERC20 is IERC20Upgradeable {
  function increaseRewardERC1155(address _to,  uint256 _value) external;
  function increaseRewardERC721(address _to,  uint256 _value) external;
}
