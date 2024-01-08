// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/// @title FYToken
/// @author David Lucid <david@rari.capital> (https://github.com/davidlucid)
/// @author David Mihal (https://github.com/dmhial)
/// @notice Rari Ethereum Pool Reimbursement Tokens (REPT-b) are YieldSpace fyTokens representing future reimbursements to Rari Ethereum Pool hack victims.
interface IFYToken {
    /// @dev Asset that is returned on redemption.
    function underlying() external view returns (address);

    /// @dev Unix time at which redemption of fyToken for underlying are possible
    function maturity() external view returns (uint256);
}
