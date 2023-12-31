// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import "./IERC20MetadataUpgradeable.sol";

import "./ICoefficient.sol";

interface IERC20Minter is ICoefficient {
    /// @notice Mint token
    /// @param minterOwner The address of the owner of the IoT device
    /// @param minter The IoT device address
    /// @param deviceType The IoT device type
    /// @return Returns true for a successful mint, false for unsuccessful
    function enableDevice(
        address minterOwner,
        address minter,
        uint16 deviceType
    ) external returns (bool);

    /// @notice Suspend minter when the system detect a problem from the IoT device's action
    /// @param device Address of the IoT device
    function suspendDevice(address device) external;

    /// @notice Mint token
    /// @param minter The minter which will be allowed to mint
    /// @param amount The amount of tokens will be minted
    /// @param nonce IoT device's nonce number (change after each time mint function is successfully called)
    /// @param v Part of signature which use for verification
    /// @param r Part of signature which use for verification
    /// @param s Part of signature which use for verification
    /// @return Returns true for a successful mint, false for unsuccessful
    function mint(
        address minter,
        uint256 amount,
        uint256 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /// @notice Get nonce of the IoT device
    /// @param minter Address of the IoT device
    function getNonce(address minter) external view returns (uint256);

    /// @notice Emitted when max mint amount of a device type is changed
    /// @param deviceType IoT device type
    /// @param value new max mint amount of each signature
    event ChangeLimit(uint32 indexed deviceType, uint256 value);

    /// @notice Emitted when an IoT device was accepted to become a minter
    /// @param owner The owner of minter device
    /// @param device The address of minter device
    event EnableDevice(address indexed owner, address indexed device);

    /// @notice Emitted when an IoT device is disabled
    /// @param device The address of the IoT device
    event SuspendDevice(address indexed device);
}
