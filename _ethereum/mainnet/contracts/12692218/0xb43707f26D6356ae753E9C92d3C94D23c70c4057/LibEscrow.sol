// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import "./LibDapps.sol";
import "./LibLoans.sol";
import "./PriceAggLib.sol";
import "./EnumerableSet.sol";

// Interfaces
import "./IERC20.sol";
import "./ILoansEscrow.sol";

// Storage
import "./market.sol";

library LibEscrow {
    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function e(uint256 loanID) internal view returns (ILoansEscrow e_) {
        e_ = s().loanEscrows[loanID];
    }

    function exists(uint256 loanID) internal view returns (bool) {
        return address(e(loanID)) != address(0);
    }

    /**
     * @notice It returns a list of tokens owned by a loan escrow
     * @param loanID uint256 index used to return our token list
     * @return t_ which is a list of tokens
     */
    function getEscrowTokens(uint256 loanID)
        internal
        view
        returns (EnumerableSet.AddressSet storage t_)
    {
        t_ = s().escrowTokens[loanID];
    }

    /**
     * @notice It returns the balance of a respective token in a loan escrow
     * @param loanID uint256 index used to point to our loan escrow
     * @param token address of respective token to give us the balance of in our loan escrow
     * @return uint256 balance of respective token returned in an escrow loan
     */
    function balanceOf(uint256 loanID, address token)
        internal
        view
        returns (uint256)
    {
        return exists(loanID) ? IERC20(token).balanceOf(address(e(loanID))) : 0;
    }

    /**
     * @notice Adds or removes tokens held by the Escrow contract
     * @param loanID The loan ID to update the token list for
     * @param tokenAddress The token address to be added or removed
     */
    function tokenUpdated(uint256 loanID, address tokenAddress) internal {
        // Skip if is lending token
        if (LibLoans.loan(loanID).lendingToken == tokenAddress) return;

        EnumerableSet.AddressSet storage tokens = s().escrowTokens[loanID];
        bool contains = EnumerableSet.contains(tokens, tokenAddress);
        if (balanceOf(loanID, tokenAddress) > 0) {
            if (!contains) {
                EnumerableSet.add(tokens, tokenAddress);
            }
        } else if (contains) {
            EnumerableSet.remove(tokens, tokenAddress);
        }
    }

    /**
     * @notice Calculate the value of the loan by getting the value of all tokens the Escrow owns.
     * @param loanID The loan ID to calculate value for
     * @return value_ Escrow total value denoted in the lending token.
     */
    function calculateTotalValue(uint256 loanID)
        internal
        view
        returns (uint256 value_)
    {
        if (!exists(loanID)) {
            return 0;
        }

        address lendingToken = LibLoans.loan(loanID).lendingToken;
        value_ += balanceOf(loanID, lendingToken);

        EnumerableSet.AddressSet storage tokens = getEscrowTokens(loanID);
        if (EnumerableSet.length(tokens) > 0) {
            for (uint256 i = 0; i < EnumerableSet.length(tokens); i++) {
                uint256 tokenBal =
                    balanceOf(loanID, EnumerableSet.at(tokens, i));
                value_ += PriceAggLib.valueFor(
                    EnumerableSet.at(tokens, i),
                    lendingToken,
                    tokenBal
                );
            }
        }
    }
}
