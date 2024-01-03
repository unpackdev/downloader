//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SettingsLib.sol";

interface IVaultsSettings {
    event VaultSettingCreated(
        address indexed creator,
        address indexed vault,
        uint256 value,
        uint256 min,
        uint256 maxs
    );

    event VaultSettingRemoved(address indexed remover, bytes32 name);

    function createVaultSetting(
        address vault,
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeVaultSetting(address vault, bytes32 name) external;

    function getVaultSetting(address vault, bytes32 name)
        external
        view
        returns (SettingsLib.Setting memory);

    function getVaultSettingValue(address vault, bytes32 name) external view returns (uint256);

    function hasVaultSetting(address vault, bytes32 name) external view returns (bool);

    function getVaultSettingOrDefaultValue(address vault, bytes32 name)
        external
        view
        returns (uint256);

    function getVaultSettingOrDefault(address vault, bytes32 name)
        external
        view
        returns (SettingsLib.Setting memory);

    function hasVaultSettingOrDefault(address vault, bytes32 name) external view returns (bool);
}
