// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import "./IAToken.sol";
import "./ILendingPool.sol";

interface IATokenWithPool is IAToken {
    function POOL() external view returns (ILendingPool);
}
