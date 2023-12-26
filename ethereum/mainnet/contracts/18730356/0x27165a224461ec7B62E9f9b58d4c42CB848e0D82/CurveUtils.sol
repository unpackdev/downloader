// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./IERC20Metadata.sol";
import "./Stats.sol";

library CurveUtils {
    function getDecimals(address token) internal view returns (uint256) {
        if (token == Stats.CURVE_ETH) {
            return 18;
        } else {
            return IERC20Metadata(token).decimals();
        }
    }
}
