// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFlashLoanReceiverV2.sol";
import "./ILendingPoolAddressesProviderV2.sol";
import "./ILendingPoolV2.sol";

/** 
    !!!
    Never keep funds permanently on your FlashLoanReceiverBase contract as they could be 
    exposed to a 'griefing' attack, where the stored funds are used by an attacker.
    !!!
 */
abstract contract FlashLoanReceiverBaseV2 is IFlashLoanReceiverV2 {
    using SafeERC20 for IERC20;

    ILendingPoolAddressesProviderV2 public immutable override ADDRESSES_PROVIDER;
    ILendingPoolV2 public immutable override LENDING_POOL;

    constructor(address provider) {
        ADDRESSES_PROVIDER = ILendingPoolAddressesProviderV2(provider);
        LENDING_POOL = ILendingPoolV2(ILendingPoolAddressesProviderV2(provider).getLendingPool());
    }

    receive() external payable {}
}
