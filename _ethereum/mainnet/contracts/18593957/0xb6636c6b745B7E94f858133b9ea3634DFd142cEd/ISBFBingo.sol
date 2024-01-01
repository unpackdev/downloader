// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

interface ISBFBingo {
    error EthTransferFailed();
    error AlreadyPaid();
    error NoWin();
    error CannotExceedMaxSentence();
    error InsufficientPayment();
    error FinalSentenceNotSet();
    error FinalSentenceAlreadySet();
    error InvalidAddress();
    error AccessDenied();
    error EntriesClosed();
    error EntriesOpen();

    event NewEntry(address indexed account, uint256 sentenceMonths, uint256 amountOfEntries);
    event FinalSentenceSet(address indexed account, uint256 sentenceMonths);
    event UserPaid(address indexed account, uint256 payout);
    event TeamPaid(address indexed account, uint256 payout);

    function play(uint256 sentenceMonths, uint256 amountOfEntries) external payable;

    function setFinalSentence(uint256 sentenceMonths) external;

    function redeem() external;

    function withdrawTeamEarnings() external;

    function getMonthsPlayedOnForAddress(address account) external view returns (uint256[] memory);

    function getEntriesForMonthForAddress(address account, uint256 sentenceMonth) external view returns (uint256);

    function getTotalEntriesForMonth(uint256 sentenceMonth) external view returns (uint256);
}
