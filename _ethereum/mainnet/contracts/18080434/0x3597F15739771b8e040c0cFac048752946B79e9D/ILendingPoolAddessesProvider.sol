// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import "./ILendingPool.sol";

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (ILendingPool);
}
