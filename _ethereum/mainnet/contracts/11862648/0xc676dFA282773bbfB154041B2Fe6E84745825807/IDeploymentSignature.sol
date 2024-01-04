// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

interface IDeploymentSignature {
  function deploymentSignature() external view returns (bytes4 signature);
}
