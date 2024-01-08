// SPDX-License-Identifier: MIT

// v1:
//  - https://docs.yearn.finance/developers/yvaults-documentation/vault-interfaces#ivault
//  - https://github.com/yearn/yearn-protocol/blob/develop/interfaces/yearn/IVault.sol
//
// Current:
//  - https://etherscan.io/address/0x19D3364A399d251E894aC732651be8B0E4e85001#code
//  - https://github.com/yearn/yearn-vaults/blob/v0.3.0/contracts/Vault.vy

pragma solidity ^0.7.6;

interface IVault {
    function decimals() external view returns (uint256);

    /**
     * @notice Gives the price for a single Vault share.
     * @dev See dev note on `withdraw`.
     * @return The value of a single share.
     */
    function pricePerShare() external view returns (uint256);

    /**
     * @notice
     *     Deposits `_amount` `token`, issuing shares to `recipient`. If the
     *     Vault is in Emergency Shutdown, deposits will not be accepted and this
     *     call will fail.
     * @dev
     *     Measuring quantity of shares to issues is based on the total
     *     outstanding debt that this contract has ("expected value") instead
     *     of the total balance sheet it has ("estimated value") has important
     *     security considerations, and is done intentionally. If this value were
     *     measured against external systems, it could be purposely manipulated by
     *     an attacker to withdraw more assets than they otherwise should be able
     *     to claim by redeeming their shares.
     *     On deposit, this means that shares are issued against the total amount
     *     that the deposited capital can be given in service of the debt that
     *     Strategies assume. If that number were to be lower than the "expected
     *     value" at some future point, depositing shares via this method could
     *     entitle the depositor to *less* than the deposited value once the
     *     "realized value" is updated from further reports by the Strategies
     *     to the Vaults.
     *     Care should be taken by integrators to account for this discrepancy,
     *     by using the view-only methods of this contract (both off-chain and
     *     on-chain) to determine if depositing into the Vault is a "good idea".
     * @param _amount   The quantity of tokens to deposit, defaults to all.
     * @param recipient The address to issue the shares in this Vault to. Defaults
     *                  to the caller's address.
     * @return The issued Vault shares.
     */
    function deposit(uint256 _amount, address recipient)
        external
        returns (uint256);

    /**
     * @notice
     *     Withdraws the calling account's tokens from this Vault, redeeming
     *     amount `_shares` for an appropriate amount of tokens.
     *     See note on `setWithdrawalQueue` for further details of withdrawal
     *     ordering and behavior.
     * @dev
     *     Measuring the value of shares is based on the total outstanding debt
     *     that this contract has ("expected value") instead of the total balance
     *     sheet it has ("estimated value") has important security considerations,
     *     and is done intentionally. If this value were measured against external
     *     systems, it could be purposely manipulated by an attacker to withdraw
     *     more assets than they otherwise should be able to claim by redeeming
     *     their shares.
     *     On withdrawal, this means that shares are redeemed against the total
     *     amount that the deposited capital had "realized" since the point it
     *     was deposited, up until the point it was withdrawn. If that number
     *     were to be higher than the "expected value" at some future point,
     *     withdrawing shares via this method could entitle the depositor to
     *     *more* than the expected value once the "realized value" is updated
     *     from further reports by the Strategies to the Vaults.
     *     Under exceptional scenarios, this could cause earlier withdrawals to
     *     earn "more" of the underlying assets than Users might otherwise be
     *     entitled to, if the Vault's estimated value were otherwise measured
     *     through external means, accounting for whatever exceptional scenarios
     *     exist for the Vault (that aren't covered by the Vault's own design.)
     * @param maxShares How many shares to try and redeem for tokens, defaults to
     *                  all.
     * @param recipient The address to issue the shares in this Vault to. Defaults
     *                  to the caller's address.
     * @param maxLoss   The maximum acceptable loss to sustain on withdrawal. Defaults
     *                  to 0%.
     * @return The quantity of tokens redeemed for `_shares`.
     */
    function withdraw(
        uint256 maxShares,
        address recipient,
        uint256 maxLoss
    ) external returns (uint256);

    function balanceOf(address) external view returns (uint256);

    /**
     * @notice
     *     Transfers shares from the caller's address to `receiver`. This function
     *     will always return true, unless the user is attempting to transfer
     *     shares to this contract's address, or to 0x0.
     * @param receiver  The address shares are being transferred to. Must not be
     *                   this contract's address, must not be 0x0.
     * @param amount    The quantity of shares to transfer.
     * @return
     *     True if transfer is sent to an address other than this contract's or
     *     0x0, otherwise the transaction will fail.
     */
    function transfer(address receiver, uint256 amount) external returns (bool);
}
