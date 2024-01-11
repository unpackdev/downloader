// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IAdapter.sol";
import "./ICurvePool.sol";

interface ICurveV1Adapter is IAdapter, ICurvePool {
    /// @dev Swap all assets into new one. Designed to simplify closure and liquidation process
    /// @param rateMinRAY minimum rate which is acceptable (in RAY format). amountOutMin = balance * rateMinRA / RAY
    function exchange_all(
        int128 i,
        int128 j,
        uint256 rateMinRAY
    ) external;

    function add_all_liquidity_one_coin(int128 i, uint256 rateMinRAY) external;

    function remove_all_liquidity_one_coin(int128 i, uint256 minRateRAY)
        external;

    //
    // GETTERS
    //
    function lp_token() external view returns (address);
}
