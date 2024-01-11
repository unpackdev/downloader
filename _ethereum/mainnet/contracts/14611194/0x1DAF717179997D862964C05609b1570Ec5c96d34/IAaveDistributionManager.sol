// SPDX-License-Identifier: MIT
// File contracts/interfaces/IAaveDistributionManager.sol

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;
import "./DistributionTypes.sol";

interface IAaveDistributionManager {
  function configureAssets(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput)
    external;
}