//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IPool.sol";

interface IPoolView {
    function maxFYTokenOut(IPool pool) external view returns (uint128);
}
