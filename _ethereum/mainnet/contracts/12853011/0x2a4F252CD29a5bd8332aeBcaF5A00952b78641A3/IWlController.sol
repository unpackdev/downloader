// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Interface of Whitelist controller.
 */
interface IWlController {
    function isInvestorAddressActive(address account) external view returns (bool);
}
