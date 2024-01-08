//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;
}
