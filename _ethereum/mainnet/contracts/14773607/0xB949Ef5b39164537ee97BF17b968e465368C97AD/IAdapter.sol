// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import "./ICreditManagerV2.sol";

enum AdapterType {
    NO_SWAP, // 0 - 1
    UNISWAP_V2, // 1 - 2
    UNISWAP_V3, // 2 - 4
    CURVE_V1_2ASSETS, // 3 - 8
    CURVE_V1_3ASSETS, // 4 - 16
    CURVE_V1_4ASSETS, // 5 - 32
    CURVE_V1_STETH, // 6 - 64
    CURVE_V1_GAUGE, // 7 - 128
    CURVE_V1_MINTER, // 8 - 256
    YEARN_V2, // 9 - 512
    CONVEX_V1_BASE_REWARD_POOL, // 10 - 1024
    CONVEX_V1_BOOSTER, // 11 - 2048
    CONVEX_V1_CLAIM_ZAP, // 12 - 4096
    LIDO_V1 // 13 - 8192
}

interface IAdapter {
    /// @dev returns creditManager instance
    function creditManager() external view returns (ICreditManagerV2);

    /// @dev returns creditFacade address
    function creditFacade() external view returns (address);

    function targetContract() external view returns (address);

    /// @dev returns type of Gearbox adapter
    function _gearboxAdapterType() external pure returns (AdapterType);

    /// @dev returns adapter version
    function _gearboxAdapterVersion() external pure returns (uint16);
}
