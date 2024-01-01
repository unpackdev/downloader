// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./LGate.sol";

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IGatorV1CustomerActions {
    /// @notice 申请成为门户
    /// @dev 申请成为门户
    function addGater(LGate.Info memory _gator) external;

    /// @notice 门户添加门户详情信息(需要是申请成为的门户的地址才能调用)
    /// @dev 门户添加门户详情信息(需要是申请成为的门户的地址才能调用)
    function addGaterDetailInfo(LGate.DetailInfo memory) external;

    function addfullGater(
        LGate.Info memory _gator,
        LGate.DetailInfo memory _gatorDatailinfo
    ) external;
}
