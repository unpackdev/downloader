// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./LGate.sol";

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IGatorV1State {
    /// @notice 判断调用者是否是市场已经认证门户
    /// @dev 判断调用者是否是市场已经认证门户
    function isValidGator() external view returns (bool);

    function isValidGator(address caller) external view returns (bool);

    /// @notice 调用者判断传入地址是否是市场已经认证门户
    /// @dev 调用者判断传入地址是否是市场已经认证门户
    function isValidGatorFromAddress(
        address vgaddress
    ) external view returns (bool);

    /// @notice 调用者判断传入地址是否是市场已经认证门户
    /// @dev 调用者判断传入地址是否是市场已经认证门户
    function isValidGatorWebFromAddress(
        address vgaddress,
        bytes32 webaddress
    ) external view returns (bool);

    /// @notice 获取门户调用者的门户编号
    /// @dev 获取门户调用者的门户编号
    function getGaterNo() external view returns (uint128);

    /// @notice 调用者获取传入地址对应的门户编号
    /// @dev 调用者获取传入地址对应的门户编号
    function getGaterNoFromAddress(
        address _gateAddress
    ) external view returns (uint128);

    /// @notice 调用者获取门户编号对应的门户信息
    /// @dev 调用者获取门户编号对应的门户信息
    function getGaterInfo(
        uint8 _gateNumber
    ) external view returns (LGate.Info memory);

    /// @notice 调用者获取门户地址对应的门户信息
    /// @dev 调用者获取门户地址对应的门户信息
    function getGaterInfo(
        address _gateaddress
    ) external view returns (LGate.Info memory);

    /// @notice 通过门户地址获取门户详情
    /// @dev 通过门户地址获取门户详情
    function getGaterDetailInfo(
        address _gateaddress
    ) external view returns (LGate.DetailInfo memory);

    /// @notice 通过门户编号获取门户详情
    /// @dev 通过门户编号获取门户详情
    function getGaterDetailInfo(
        uint8 _gateNumber
    ) external view returns (LGate.DetailInfo memory);

    /// @notice 调用者获取市场最大门户编号、或者是下一个门户申请者的编号
    /// @dev 调用者获取市场最大门户编号、或者是下一个门户申请者的编号
    function getMaxGateNumber() external view returns (uint128);

    function marketorContractAddress() external view returns (address);
}
