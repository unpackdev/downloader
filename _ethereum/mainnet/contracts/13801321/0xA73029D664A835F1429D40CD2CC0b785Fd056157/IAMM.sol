// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IFeePool.sol";

interface IAMM {
    function sell(
        uint256 _seriesId,
        uint128 _amount,
        uint128 _minFee
    ) external returns (uint128);

    function feePool() external returns (IFeePool);
}
