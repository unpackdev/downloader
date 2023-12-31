// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";


interface IVicsExchange {
    /**
    @dev Exchanges the given input amount of a specific asset to an equivalent amount
        of VICS.
     */
    function swap(IERC20 asset, uint amountIn) external returns(uint amountOut);
}