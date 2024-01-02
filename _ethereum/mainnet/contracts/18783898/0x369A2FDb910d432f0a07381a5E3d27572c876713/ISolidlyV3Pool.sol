// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.5;

import "./Utils.sol";

interface ISolidlyV3Pool {
    function swap(
        address _recipient,
        bool _zeroForOne,
        int256 _amountSpecified,
        uint160 _sqrtPriceLimitX96
    ) external returns (int256 amount0, int256 amount1);
}
