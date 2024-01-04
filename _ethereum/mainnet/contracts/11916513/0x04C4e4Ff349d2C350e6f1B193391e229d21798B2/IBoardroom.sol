// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IOperator.sol";

interface IBoardroom is IOperator {
    function allocateSeigniorage(uint256 amount) external;
}
