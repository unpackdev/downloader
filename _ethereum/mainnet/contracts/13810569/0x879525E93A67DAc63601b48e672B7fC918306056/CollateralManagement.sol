// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./AddressUpgradeable.sol";

import "./AdminRole.sol";

/**
 * @notice Enables deposits and withdrawals.
 */
abstract contract CollateralManagement is AdminRole {
    using AddressUpgradeable for address payable;

    event FundsWithdrawn(address indexed to, uint256 amount);

    /**
     * @notice Accept native currency payments (i.e. fees)
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice Allows an admin to withdraw funds.
     * @dev    In normal operation only ETH is required, but this allows access to any
     *         ERC-20 funds sent to the contract as well.
     *
     * @param to        Address to receive the withdrawn funds
     * @param amount    Amount to withdrawal or 0 to withdraw all available funds
     */
    function withdrawFunds(address payable to, uint256 amount)
        public
        onlyAdmin
    {
        if (amount == 0) {
            amount = address(this).balance;
        }
        to.sendValue(amount);

        emit FundsWithdrawn(to, amount);
    }

    uint256[1000] private __gap;
}
