// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IERC721Metadata.sol";
import "./IERC721.sol";

interface INeverFearTruth is IERC721, IERC721Metadata {
  function mint(address receiver) external;

  function totalSupply() external view returns (uint256);

  function MAX_SUPPLY() external view returns (uint256);
}
