// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ITokenOracle.sol";

interface IVspOracle is ITokenOracle {
    /**
     * @notice Update underlying price providers (i.e. UniswapV2-Like)
     */
    function update() external;
}
