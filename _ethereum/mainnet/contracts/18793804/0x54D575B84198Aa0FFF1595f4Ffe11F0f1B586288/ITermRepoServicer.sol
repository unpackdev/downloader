//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoServicer represents a contract that manages all
interface ITermRepoServicer {
    /// @param borrower The address of the borrower to query
    /// @return The total repurchase price due at maturity for a given borrower
    function getBorrowerRepurchaseObligation(
        address borrower
    ) external view returns (uint256);
}
