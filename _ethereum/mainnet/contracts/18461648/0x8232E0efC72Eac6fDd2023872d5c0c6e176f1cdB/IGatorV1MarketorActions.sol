// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./LGate.sol";

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IGatorV1MarketorActions {
    /// @notice 市场管理员冻结门户
    /// @dev 市场管理员冻结门户
    function lockGatebyMarketor(address _gatoraddress) external;

    /// @notice 市场管理员解冻门户
    /// @dev 市场管理员解冻门户
    function unlockGatebyMarketor(address _gatoraddress) external;

    /// @notice 市场管理员更新门户
    /// @dev 市场管理员更新门户
    function updateGatebyMarketor(LGate.Info memory _gator) external;

    /// @notice 市场管理员删除门户
    /// @dev 市场管理员删除门户
    function delGatebyMarketor(address _gator) external;

    /// @notice 设置门户合约的管理员合约
    /// @dev 设置门户合约的管理员合约
    function setGaterEnv(
        address _marketorContractAddress,
        address _marketCreator
    ) external;
}
