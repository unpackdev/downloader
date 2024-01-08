// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./PausableMods.sol";

// Interfaces
import "./ILoansEscrow.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

// Storage
import "./market.sol";

// Libraries
import "./LibDapps.sol";
import "./LibLoans.sol";
import "./LibEscrow.sol";
import "./PriceAggLib.sol";

contract EscrowClaimTokensFacet is PausableMods {
    using SafeERC20 for IERC20;
    /**
     * @notice Notifies when the Escrow's tokens have been claimed.
     * @param recipient address where the tokens where sent to.
     */
    event TokensClaimed(address recipient);

    /**
     * @notice Sends the tokens owned by this escrow to the owner.
     * @param loanID The id of the loan being used.
     */
    function claimTokens(uint256 loanID) external paused("", false) {
        require(
            LibLoans.loan(loanID).borrower == msg.sender,
            "Teller: claim not borrower"
        );
        require(
            LibLoans.loan(loanID).status == LoanStatus.Closed,
            "Teller: loan not closed"
        );

        EnumerableSet.AddressSet storage tokens =
            MarketStorageLib.store().escrowTokens[loanID];
        for (uint256 i = 0; i < EnumerableSet.length(tokens); i++) {
            uint256 balance =
                LibEscrow.balanceOf(loanID, EnumerableSet.at(tokens, i));
            if (balance > 0) {
                LibEscrow.e(loanID).claimToken(
                    EnumerableSet.at(tokens, i),
                    msg.sender,
                    balance
                );
            }
        }

        emit TokensClaimed(msg.sender);
    }
}
