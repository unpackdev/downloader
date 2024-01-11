// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.9;

import "./IERC721Upgradeable.sol";

interface IERC721BatchTransfer is IERC721Upgradeable {
  /**
   * @notice Batch transfer of tokens from one address to another
   */
  function batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds
  ) external;

  /**
   * @notice Safe batch transfer of tokens from one address to another
   */
  function batchSafeTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    bytes memory data_
  ) external;
}
