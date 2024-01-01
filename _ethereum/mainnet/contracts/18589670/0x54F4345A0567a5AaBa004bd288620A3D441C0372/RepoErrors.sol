// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library RepoErrors {
    error InsufficientBalance();
    error NothingToWithdraw();
    error InvalidToken();
    error InvalidIndex(); // issue with code
    error RepoPaused();
    error RepoAlreadyExistsForUser();
    error InsufficientEligibleCurrencyAmount();
    error RepoExpired();
    error NoActiveRepo();
    error NoActiveRepoForUser();
    error RepoStillActive();

    // so basically there is a possible case where there are no cleared Depositors.
    //
    // Example: 
    // 1. At the time of sellRepo, there is one cleared Depositor for 1000 currencyToken.
    // 2. sellRepo is called, and repoToken is sold for all 1000 currencyToken.
    // 3. The repo expires.
    // 4. A new depositor deposits 1000 more currencyToken. At this point this is 1000 currencyToken in the contract, and 1 address each in clearedDepositorsList and pendingAddressList
    // 5. Before the new depositor's deposit clears, the cleared depositor withdraws all 1000 currency tokens.
    // 6. Now, there are 0 cleared depositors, and an expired repo!
    //
    // If defaultRepo is called in this case, the pending depositor would still be owed 1000 currency tokens, and no one would have ownership of all the defaulted repo tokens.
    // Therefore we need at least one cleared depositor to be present before defaultRepo() can be called; furthermore, we need the total number of cleared Deposits to be greater than or equal to 1000 currencyTokens.
    // Note this is guaranteed to happen within pendingTime as all pendingDeposits will be cleared then, and no one else can withdraw since there are no more tokens left in the contract.
    // Note it is fine if there are no cleared depositors present when buybackRepo() is called, as the extra currencyToken accrued would just sit in the contract for the owner presumably.
    error InsufficientClearedDeposits();

    // this occurs when the amount of currencyToken you are trying to withdraw exceeds totalEligibleBalance, which is the unborrowed cleared balance at the moment
    // if you receive this error, this likely means the contract has enough currencyToken to pay you out, but some of that belongs to pending balances which do not belong to you. Your funds are locked in a repo at the moment, while the 
    // pending funds belonging to someone else are not
    error WithdrawingMoreThanEligible(); 
}