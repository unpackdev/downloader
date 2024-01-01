// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./ISBFBingo.sol";

/*+++++=============================================================================++++++
+++++================================+=====***+=++==================================++++++
+++++=============================+*%%#****##***#**++===============================++++++
+++++============================+###%%%%%%%%##*#%#**++++==========================+++++++
++++=========================++**#%##%#%@@@@%%%%%@%%#**##*==========================++++++
+++=========================++*%#%%%%%%%%@@@@@@@@@@%%%#%%%#========================+++++++
+++=======================*##*#%%@@@@@%%%@@@@@@@@@%%%%%%%@#+=======================+++++++
++======================+#%%%#%%%@@@@@@@%%%%%%%%@@%%%#%%%%%#+======================+++++++
++=====================+**#%@@%%@@@@@%%%@%%%####%###%@%%%%%%%*+=====================++++++
+======================+**%%@@@@%%%%%%**##*++===++++#%@@@@@%@#+======================+++++
+======================+%%%@@@@@@@%#*+=----::...:-==+*%@@@%@%%%*+===================++++++
+======================+%@%%@@@@@%*=--::::...::------+#@@@@%@%@%+==================+++++++
+=======================#%@@@@@@@#*++*##*+=--+*%%#***+*@%%%%%%%#====================++++++
=========================*@@@%@@%*#%%#%%#%*::+*+*#**+-=%@@%@@%+====================+++++++
==========================#@@@@@@+==++==-==::-::--::::-*@@@@%#=====================+++++++
===========================+*%@@@*=-::..:-=:.:-:....:-=+%%%@#+=====================+++++++
=============================*%%%#+=-::::++-:=+-:-::-=+*+=#*=======================+++++++
==============================++*%#*==---+#%%*=----===+*#%*========================+++++++
=================================#%**+=+****+==+++=--=+**+========================++++++++
+=================================#%**==-=+++==---===+#+==========================++++++++
+==================================*%%#+=----:::--=+*#*==========================+++++++++
+===============================+*+*%%%%*+==--==+*#%%#+++========================+++++++++
++===========================++*#%%@@%%@%%%%#%%%%%%%#*++++======================++++++++++
+++========================+++++##%%%%%%%%@@@@@%%%#**+=++======================++++++++++*/

contract SBFBingo is AccessControl, ReentrancyGuard, ISBFBingo {
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    uint256 public constant PRICE_PER_ENTRY_IN_WEI = 100000000000000000;
    uint256 public constant ENTRY_DEADLINE = 1711598399;

    address public admin;
    uint256 public totalEntries;
    uint256 public finalSentence;
    uint256 public totalAmountWagered;
    uint256 public totalAmountWhenSentenceSet;
    bool public finalSentenceSet;
    bool public teamEarningsPaid;
    mapping(uint256 => uint256) monthsToNumberOfEntries;
    mapping(address => mapping(uint256 => uint256)) numberOfEntriesPerMonthByAddress;
    mapping(address => bool) userPaid;
    mapping(address => EnumerableSet.UintSet) monthsEnteredByAddress;

    constructor(address admin_) {
        if (admin_ == address(0)) revert InvalidAddress();

        _setupRole(ADMIN_ROLE, admin_);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);

        admin = admin_;
    }

    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert AccessDenied();
        _;
    }

    modifier finalSentenceNotRevealed() {
        if (finalSentenceSet) revert FinalSentenceAlreadySet();
        _;
    }

    modifier finalSentenceRevealed() {
        if (!finalSentenceSet) revert FinalSentenceNotSet();
        _;
    }

    modifier entriesAreOpen() {
        if (block.timestamp > ENTRY_DEADLINE) revert EntriesClosed();
        _;
    }

    modifier entriesAreClosed() {
        if (block.timestamp <= ENTRY_DEADLINE) revert EntriesOpen();
        _;
    }

    /// @dev Play X times on a month.
    function play(uint256 sentenceMonths, uint256 amountOfEntries) external payable override entriesAreOpen nonReentrant {
        if (msg.value < (amountOfEntries * PRICE_PER_ENTRY_IN_WEI)) revert InsufficientPayment();
        if (numberOfEntriesPerMonthByAddress[msg.sender][sentenceMonths] == 0) {
            monthsEnteredByAddress[msg.sender].add(sentenceMonths);
        }
        numberOfEntriesPerMonthByAddress[msg.sender][sentenceMonths] += amountOfEntries;
        monthsToNumberOfEntries[sentenceMonths] += amountOfEntries;
        totalEntries += amountOfEntries;
        totalAmountWagered += msg.value;
        (bool sent, ) = payable(admin).call{ value: ((msg.value * 25) / 100) }("");
        if (!sent) revert EthTransferFailed();
        emit NewEntry(msg.sender, sentenceMonths, amountOfEntries);
    }

    /// @dev Sets the final sentence once entries is closed.
    function setFinalSentence(
        uint256 sentenceMonths
    ) external override onlyAdmin entriesAreClosed finalSentenceNotRevealed {
        finalSentence = sentenceMonths;
        finalSentenceSet = true;
        totalAmountWhenSentenceSet = address(this).balance;
        emit FinalSentenceSet(msg.sender, sentenceMonths);
    }

    /// @dev Redeems the winning share of the caller. Fails if the caller has did not win.
    function redeem() external override finalSentenceRevealed nonReentrant {
        if (userPaid[msg.sender]) revert AlreadyPaid();
        uint256 winningEntriesOfUser = numberOfEntriesPerMonthByAddress[msg.sender][finalSentence];
        if (winningEntriesOfUser == 0) revert NoWin();
        uint256 totalWinningEntries = monthsToNumberOfEntries[finalSentence];
        uint256 payout = (totalAmountWhenSentenceSet * winningEntriesOfUser) / totalWinningEntries;
        userPaid[msg.sender] = true;
        (bool sent, ) = payable(msg.sender).call{ value: payout }("");
        if (!sent) revert EthTransferFailed();
        emit UserPaid(msg.sender, payout);
    }

    /// @dev Withdraws the earnings for the team if any.
    function withdrawTeamEarnings() external override onlyAdmin finalSentenceRevealed nonReentrant {
        if (teamEarningsPaid) revert AlreadyPaid();
        uint256 totalWinningEntries = monthsToNumberOfEntries[finalSentence];
        if (totalWinningEntries > 0) revert AlreadyPaid();
        teamEarningsPaid = true;
        uint256 payout = address(this).balance;
        (bool sent, ) = payable(admin).call{ value: payout }("");
        if (!sent) revert EthTransferFailed();
        emit TeamPaid(admin, payout);
    }

    /// @dev Gets a list of months an account has been played on.
    function getMonthsPlayedOnForAddress(address account) external view override returns (uint256[] memory) {
        return monthsEnteredByAddress[account].values();
    }

    /// @dev Gets the total amount of entries on a specific month for an account.
    function getEntriesForMonthForAddress(
        address account,
        uint256 sentenceMonth
    ) external view override returns (uint256) {
        return numberOfEntriesPerMonthByAddress[account][sentenceMonth];
    }

    /// @dev Gets the total amount of entries on a specific month.
    function getTotalEntriesForMonth(uint256 sentenceMonth) external view override returns (uint256) {
        return monthsToNumberOfEntries[sentenceMonth];
    }
}
