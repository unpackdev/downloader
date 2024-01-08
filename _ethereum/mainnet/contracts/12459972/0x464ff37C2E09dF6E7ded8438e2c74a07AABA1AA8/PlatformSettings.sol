//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Libraries
import "./Address.sol";
import "./SettingsLib.sol";

// Contracts
import "./RolesManagerConsts.sol";
import "./PlatformSettingsConsts.sol";

// Interfaces
import "./IPlatformSettings.sol";
import "./IRolesManager.sol";

contract PlatformSettings is IPlatformSettings {
    using Address for address;
    using SettingsLib for SettingsLib.Setting;

    /** Constants */

    /* State Variables */

    /**
        @notice This mapping represents the platform settings where:

        - The key is the platform setting name.
        - The value is the platform setting. It includes the value, minimum and maximum values.
     */
    mapping(bytes32 => SettingsLib.Setting) public settings;

    bool public paused;

    address public override rolesManager;

    address public override consts;

    /** Modifiers */

    modifier onlyPauser(address account) {
        _rolesManager().requireHasRole(
            _rolesManagerConsts().PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _rolesManager().requireHasRole(
            _rolesManagerConsts().CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    /* Constructor */

    constructor(address rolesManagerAddress) public {
        require(rolesManagerAddress.isContract(), "ROLES_MANAGER_MUST_BE_CONTRACT");
        rolesManager = rolesManagerAddress;
        consts = address(new PlatformSettingsConsts());
    }

    /** External Functions */

    /**
        @notice It creates a new platform setting given a name, value, min and max values.
        @param name setting name to create.
        @param value the initial value for the given setting name.
        @param min the min value for the setting.
        @param max the max value for the setting.
     */
    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external override onlyConfigurator(msg.sender) {
        require(name != "", "NAME_MUST_BE_PROVIDED");
        settings[name].create(value, min, max);

        emit PlatformSettingCreated(name, msg.sender, value, min, max);
    }

    /**
        @notice It updates an existent platform setting given a setting name.
        @notice It only allows to update the value (not the min or max values).
        @notice In case you need to update the min or max values, you need to remove it, and create it again.
        @param settingName setting name to update.
        @param newValue the new value to set.
     */
    function updateSetting(bytes32 settingName, uint256 newValue)
        external
        onlyConfigurator(msg.sender)
    {
        uint256 oldValue = settings[settingName].update(newValue);

        emit PlatformSettingUpdated(settingName, msg.sender, oldValue, newValue);
    }

    /**
        @notice Removes a current platform setting given a setting name.
        @param name to remove.
     */
    function removeSetting(bytes32 name) external override onlyConfigurator(msg.sender) {
        uint256 oldValue = settings[name].value;
        settings[name].remove();

        emit PlatformSettingRemoved(name, msg.sender, oldValue);
    }

    function pause() external override onlyPauser(msg.sender) {
        require(!paused, "PLATFORM_ALREADY_PAUSED");

        paused = true;

        emit PlatformPaused(msg.sender);
    }

    function unpause() external override onlyPauser(msg.sender) {
        require(paused, "PLATFORM_ISNT_PAUSED");

        paused = false;

        emit PlatformUnpaused(msg.sender);
    }

    /* View Functions */

    function requireIsPaused() external view override {
        require(paused, "PLATFORM_ISNT_PAUSED");
    }

    function requireIsNotPaused() external view override {
        require(!paused, "PLATFORM_IS_PAUSED");
    }

    /**
        @notice It gets the current platform setting for a given setting name
        @param name to get.
        @return the current platform setting.
     */
    function getSetting(bytes32 name) external view override returns (SettingsLib.Setting memory) {
        return _getSetting(name);
    }

    /**
        @notice It gets the current platform setting value for a given setting name
        @param name to get.
        @return the current platform setting value.
     */
    function getSettingValue(bytes32 name) external view override returns (uint256) {
        return _getSetting(name).value;
    }

    /**
        @notice It tests whether a setting name is already configured.
        @param name setting name to test.
        @return true if the setting is already configured. Otherwise it returns false.
     */
    function hasSetting(bytes32 name) external view override returns (bool) {
        return _getSetting(name).exists;
    }

    /**
        @notice It gets whether the platform is paused or not.
        @return true if platform is paused. Otherwise it returns false.
     */
    function isPaused() external view override returns (bool) {
        return paused;
    }

    /** Internal functions */

    /**
        @notice It gets the platform setting for a given setting name.
        @param name the setting name to look for.
        @return the current platform setting for the given setting name.
     */
    function _getSetting(bytes32 name) internal view returns (SettingsLib.Setting memory) {
        return settings[name];
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(rolesManager);
    }

    function _rolesManagerConsts() internal view returns (RolesManagerConsts) {
        return RolesManagerConsts(_rolesManager().consts());
    }

    /** Private functions */
}
