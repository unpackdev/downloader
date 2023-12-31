// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTfi {
    /**
     * @dev Used to liquidate foreclosed loans
     * @param _loanId The id of the loan to liquidate
     */
    function liquidateOverdueLoan(uint32 _loanId) external;
}
