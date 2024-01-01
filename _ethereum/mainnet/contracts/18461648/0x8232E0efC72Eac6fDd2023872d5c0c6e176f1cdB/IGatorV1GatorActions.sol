// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./LGate.sol";

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IGatorV1GatorActions {
    /// @notice 市场认证后的门户临时冻结自己
    /// @dev 市场认证后的门户临时冻结自己
    function lockGatebyGater() external;

    /// @notice 市场认证后的门户临时解冻自己
    /// @dev 市场认证后的门户临时解冻自己
    function unlockGatebyGater() external;

    /// @notice 市场认证后的门户临时更新自己
    /// @dev 市场认证后的门户临时更新自己
    function updateGatebyGator(bytes32 _name) external;

    function updatefullGater(
        LGate.Info memory _gator,
        LGate.DetailInfo memory _gatorDatailinfo
    ) external;
}
