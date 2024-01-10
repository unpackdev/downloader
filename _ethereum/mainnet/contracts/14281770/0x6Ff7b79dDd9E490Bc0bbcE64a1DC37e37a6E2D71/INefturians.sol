// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./IERC721.sol";
import "./IAccessControl.sol";

interface INefturians is IERC721, IAccessControl {
  event UpdateNefturianArtifact(address newArtifactContract);

  function getNonce(address addr) external view returns (uint256);

  function incrementNonce(address addr) external;
}
