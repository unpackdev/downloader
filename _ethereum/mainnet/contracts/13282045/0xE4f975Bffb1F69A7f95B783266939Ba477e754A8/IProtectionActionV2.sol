// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IAction.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";

interface IProtectionActionV2 is IAction {
    /// sohint-disable-next-line func-name-mixedcase
    function slippageInBps() external view returns (uint256);

    /// sohint-disable-next-line func-name-mixedcase
    function LENDING_POOL() external view returns (ILendingPool);

    /// sohint-disable-next-line func-name-mixedcase
    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider);
}
