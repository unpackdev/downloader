// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IFlashLoanReceiver.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
    using SafeERC20 for IERC20;

    ILendingPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    ILendingPool public immutable LENDING_POOL;

    constructor(ILendingPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        LENDING_POOL = ILendingPool(provider.getLendingPool());
    }
}
