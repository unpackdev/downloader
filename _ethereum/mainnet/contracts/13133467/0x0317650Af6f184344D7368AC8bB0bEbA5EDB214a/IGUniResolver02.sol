// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

import "./IGUniPool.sol";

interface IGUniResolver02 {
    function getRebalanceParams(
        IGUniPool pool,
        uint256 amount0In,
        uint256 amount1In,
        uint256 price18Decimals
    ) external view returns (bool zeroForOne, uint256 swapAmount);
}
