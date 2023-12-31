// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IFijaERC4626Base.sol";

interface IFijaStrategy is IFijaERC4626Base {
    ///
    /// @dev emits when rebalance executes
    /// @param timestamp current timestamp when rebalance is executed
    /// @param data metadata associated with event
    ///
    event Rebalance(uint256 indexed timestamp, string data);

    ///
    /// @dev emits when harvest executes
    /// @param timestamp current timestamp when harvest is executed
    /// @param harvestResult amount of harvested funds
    /// @param profitShare amount of profits
    /// @param profitToken address of profit token
    /// @param data metadata associated with event
    ///
    event Harvest(
        uint256 indexed timestamp,
        uint256 harvestResult,
        uint256 profitShare,
        address profitToken,
        string data
    );

    ///
    /// @dev emits when emergency mode is toggled
    /// @param timestamp current timestamp when emergency mode is toggled
    /// @param turnOn flag for turning on/off emergency mode
    ///
    event EmergencyMode(uint256 indexed timestamp, bool turnOn);

    ///
    /// @dev check if there is a need to rebalance strategy funds
    /// @return bool indicating need for rebalance
    ///
    function needRebalance() external view returns (bool);

    ///
    /// @dev executes strategy rebalancing
    ///
    function rebalance() external;

    ///
    /// @dev check if there is a need to harvest strategy funds
    /// @return bool indicating need for harvesting
    ///
    function needHarvest() external view returns (bool);

    ///
    /// @dev executes strategy harvesting
    ///
    function harvest() external;

    ///
    /// @dev gets emergency mode status of strategy
    /// @return flag indicting emergency mode status
    ///
    function emergencyMode() external view returns (bool);

    ///
    /// @dev sets emergency mode on/off
    /// @param turnOn toggle flag
    ///
    function setEmergencyMode(bool turnOn) external;

    ///
    /// @dev check if there is a need for setting strategy in emergency mode
    /// @return bool indicating need for emergency mode
    ///
    function needEmergencyMode() external view returns (bool);

    ///
    /// @dev gets various strategy status parameters
    /// @return status parameters as string
    ///
    function status() external view returns (string memory);
}
