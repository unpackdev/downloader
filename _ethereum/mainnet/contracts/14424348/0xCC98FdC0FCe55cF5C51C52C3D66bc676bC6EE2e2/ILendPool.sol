// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILendPool {
    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent bTokens owned
     * E.g. User has 100 bUSDC, calls withdraw() and receives 100 USDC, burning the 100 bUSDC
     * @param reserve The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole bToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address reserve,
        uint256 amount,
        address to
    ) external returns (uint256);
}
