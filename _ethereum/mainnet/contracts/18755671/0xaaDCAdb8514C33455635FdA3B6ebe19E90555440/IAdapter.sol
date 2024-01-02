// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import "./IOwned.sol";
import "./IERC4626Upgradeable.sol";
import "./IPermit.sol";
import "./IPausable.sol";

interface IAdapter is IERC4626, IOwned, IPermit, IPausable {
    function strategy() external view returns (address);

    function strategyConfig() external view returns (bytes memory);

    function strategyDeposit(uint256 assets, uint256 shares) external;

    function strategyWithdraw(uint256 assets, uint256 shares) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function setPerformanceFee(uint256 fee) external;

    function performanceFee() external view returns (uint256);

    function highWaterMark() external view returns (uint256);

    function accruedPerformanceFee() external view returns (uint256);

    function harvest() external;

    function toggleAutoHarvest() external;

    function autoHarvest() external view returns (bool);

    function lastHarvest() external view returns (uint256);

    function harvestCooldown() external view returns (uint256);

    function setHarvestCooldown(uint256 harvestCooldown) external;

    function initialize(
        bytes memory adapterBaseData,
        address externalRegistry,
        bytes memory adapterData
    ) external;

    function decimals() external view returns (uint8);

    function decimalOffset() external view returns (uint8);
}
