//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPriceOracle.sol";

interface IPriceOracleExtended is IPriceOracle {
    function BASE_CURRENCY_UNIT() external view returns (uint256);
}
