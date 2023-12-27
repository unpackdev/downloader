// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.16;

import "./OptimisticOracleV3Interface.sol";

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./Utils.sol";

contract RatedOracle is Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    /****************************************
     *              STRUCTS                 *
     ****************************************/

    struct Violation {
        bytes32 validatorIdentifier;
        uint32 epochNumber;
        uint32 penaltyType;
        address newFeeRecipientAddress;
    }

    struct Report {
        uint32 fromEpoch;
        uint32 toEpoch;
        uint256 timestamp;
        bytes32 assertionID;
        Violation[] listViolations;
    }

    /****************************************
     *              STORAGE                 *
     ****************************************/

    Counters.Counter public reportID; // Atomic counter for identifying reports.
    mapping(bytes32 => Violation[]) public violationsForValidator; // List of settled violations for a validator.
    mapping(uint256 => mapping(bytes32 => bool)) public validatorInReport; // Whether or not a report affects a validator.
    mapping(uint256 => Report) public reports; // Mapping of the reports against their ID.
    mapping(address => bool) public approvedProposer; // Mapping giving whether or not this address is approved for proposing reports.

    uint256[] public disputedReportsID; // List of the ID reports under dispute.
    uint256[] public pendingReportsID; // List of not yet finalized reports.

    OptimisticOracleV3Interface OO; // UMA Optimistic Oracle v3.
    bytes32 public priceIdentifier = "ROPU_ETHx"; // To be replaced with custom Identifier.
    uint256 public bondAmount; // Bond amount to commit on OO with assertion.
    uint64 public challengeWindow; // Number of seconds to wait before assertion is finalized.
    uint64 public timeToSettle = 345600; // Maximum amount of time required for a disputed report to settle.

    IERC20 public bondCurrency; // Currency used as bond.

    /****************************************
     *               EVENTS                 *
     ****************************************/

    /// @notice Emitted when a new bond is set.
    /// @param _newBondAmount The new amount to set.
    /// @param _newCurrency The new currency to set.
    event NewBondSet(uint256 _newBondAmount, IERC20 _newCurrency);

    /// @notice Emitted when a new proposer is approved.
    /// @param _proposerApproved The newly approved proposer.
    event ProposerApproved(address _proposerApproved);

    /// @notice Emitted when a proposer is revoked.
    /// @param _proposerRevoked The revoked proposer.
    event ProposerRevoked(address _proposerRevoked);

    /// @notice Emitted when a new challenge window is set.
    /// @param _newChallengeWindow The new challenge window.
    event NewChallengeWindowSet(uint64 _newChallengeWindow);

    /// @notice Emitted when a new time to settle is set.
    /// @param _timeToSettle The new time to settle.
    event NewTimeToSettleSet(uint64 _timeToSettle);

    /// @notice Emitted when a report is disputed.
    /// @param _reportID The disputed report.
    event reportDisputed(uint256 _reportID);

    /// @notice Emitted when a report is settled.
    /// @param _reportID The settled report.
    event reportSettled(uint256 _reportID);

    /// @notice Emitted when a new report is brought on chain.
    /// @param _reportID The new report.
    event reportMade(uint256 _reportID);

    /// @notice Emitted when a new report is discarded.
    /// @param _reportID The discarded report.
    event reportDiscarded(uint256 _reportID);

    /****************************************
     *               ERRORS                 *
     ****************************************/

    /// @notice Thrown if msg.sender isn't an approved proposer.
    error proposerNotApproved();

    /// @notice Thrown when zero is passed as a parameter.
    error amountCanNotBeZero();

    /// @notice Thrown when address zero is passed as a parameter.
    error canNotBeAddressZero();

    /// @notice Thrown when the challenge window passed is invalid.
    error invalidChallengeWindow();

    /****************************************
     *              MODIFIER                *
     ****************************************/

    // @dev Throws if called by a unapproved proposer.
    modifier onlyApprovedProposer() {
        if (approvedProposer[msg.sender] != true) revert proposerNotApproved();
        _;
    }

    /****************************************
     *             CONSTRUCTOR              *
     ****************************************/

    /// @notice Constructs the contract.
    constructor(
        uint256 _bondAmount,
        uint64 _challengeWindow,
        address _bondCurrency,
        address _proposer,
        address _oracle
    ) {
        changeBondAmountAndCurrency(_bondAmount, IERC20(_bondCurrency));
        setChallengeWindow(_challengeWindow);
        approveProposer(_proposer);
        OO = OptimisticOracleV3Interface(_oracle);
        transferOwnership(0x7e764ED499BcBd64Bc0Ab76222C239c666d50E4D);
    }

    /****************************************
     *         GOVERNANCE FUNCTIONS         *
     ****************************************/

    /// @notice Sets the currency and amount for the bond of the assertions.
    /// @param _newBondAmount The new amount to set.
    /// @param _newCurrency The new currency to set.
    function changeBondAmountAndCurrency(
        uint256 _newBondAmount,
        IERC20 _newCurrency
    ) public onlyOwner {
        if (_newBondAmount == 0) revert amountCanNotBeZero();
        if (address(_newCurrency) == address(0)) revert canNotBeAddressZero();

        bondAmount = _newBondAmount;
        bondCurrency = _newCurrency;

        emit NewBondSet(_newBondAmount, _newCurrency);
    }

    /// @notice Allow an address to propose.
    /// @param _address the address to authorize.
    function approveProposer(address _address) public onlyOwner {
        if (_address == address(0)) revert canNotBeAddressZero();
        approvedProposer[_address] = true;
        emit ProposerApproved(_address);
    }

    /// @notice Revoke an address priviledge to propose.
    /// @param _address the address to revoke.
    function revokeProposer(address _address) external onlyOwner {
        if (_address == address(0)) revert canNotBeAddressZero();
        approvedProposer[_address] = false;
        emit ProposerRevoked(_address);
    }

    /// @notice Allow owner to withdraw funds on the contract.
    /// @dev Make sure the contract always has enough funds to commit bonds to the OptimisticOracle.
    /// @param _token The address of the ERC20 to withdraw.
    /// @param _amount The amount to withdraw.
    /// @param _to Receiver of the funds.
    function withdrawFunds(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        if (_to == address(0)) revert canNotBeAddressZero();
        IERC20(_token).safeTransfer(_to, _amount);
    }

    /// @notice Sets the size of the challenge window.
    /// @param _newChallengeWindow The new challenge window to set (in seconds).
    function setChallengeWindow(uint64 _newChallengeWindow) public onlyOwner {
        if (_newChallengeWindow > 604800 || _newChallengeWindow == 0)
            revert invalidChallengeWindow();

        challengeWindow = _newChallengeWindow;
        emit NewChallengeWindowSet(_newChallengeWindow);
    }

    /// @notice Sets the time to settle for a disputed report.
    /// @param _timeToSettle The new time to settle (in seconds).
    function setTimeToSettle(uint64 _timeToSettle) public onlyOwner {
        timeToSettle = _timeToSettle;
        emit NewTimeToSettleSet(_timeToSettle);
    }

    /// @notice Forces the removal of a report from disputedReportsID.
    /// @dev If Quorum is not reached in the dispute process, the report will not settle in the desired time frame.
    /// @param _index The index of the report to remove in the array.
    function removeDisputedReport(uint64 _index) external onlyOwner {
        emit reportDiscarded(disputedReportsID[_index]);
        Utils.removeFromArray(_index, disputedReportsID);
    }

    /****************************************
     *         INTERNAL FUNCTIONS           *
     ****************************************/

    /// @notice Settles the reports that can be settled and applies the changes to storage.
    /// @dev If a report is under dispute, will mark it as such and
    /// @dev settles it when vote is complete - 2 to 4 days later.
    function settleReports() internal {
        uint256 deletedElem = 0;
        uint256 numberOfDisputedReports = disputedReportsID.length;
        for (uint256 i = 0; i < numberOfDisputedReports; i++) {
            uint256 index = i - deletedElem;
            uint256 IDreportToSettle = disputedReportsID[index];
            if (
                block.timestamp >
                reports[IDreportToSettle].timestamp + timeToSettle
            ) {
                if (
                    OO.settleAndGetAssertionResult(
                        reports[IDreportToSettle].assertionID
                    )
                ) {
                    pushVerifiedReport(IDreportToSettle);
                    Utils.removeFromArray(index, disputedReportsID);
                    deletedElem++;
                    emit reportSettled(IDreportToSettle);
                } else {
                    Utils.removeFromArray(index, disputedReportsID);
                    deletedElem++;
                    emit reportDiscarded(IDreportToSettle);
                }
            }
        }

        deletedElem = 0;
        uint256 numberOfPendingReports = pendingReportsID.length;
        for (uint256 i = 0; i < numberOfPendingReports; i++) {
            uint256 index = i - deletedElem;
            uint256 IDreportToSettle = pendingReportsID[index];

            OptimisticOracleV3Interface.Assertion memory assertionDetails = OO
                .getAssertion(reports[IDreportToSettle].assertionID);

            if (
                assertionDetails.disputer == address(0) &&
                block.timestamp > assertionDetails.expirationTime
            ) {
                if (assertionDetails.settled == false) {
                    OO.settleAssertion(reports[IDreportToSettle].assertionID);
                }
                pushVerifiedReport(IDreportToSettle);
                Utils.removeFromArray(index, pendingReportsID);
                deletedElem++;
                emit reportSettled(IDreportToSettle);
            }

            if (assertionDetails.disputer != address(0)) {
                reports[IDreportToSettle].timestamp = block.timestamp;
                disputedReportsID.push(IDreportToSettle);
                Utils.removeFromArray(index, pendingReportsID);
                deletedElem++;
                emit reportDisputed(IDreportToSettle);
            }
        }
    }

    /// @notice Attributes the report's violation to the concerned validators.
    /// @param _reportID The report to push.
    function pushVerifiedReport(uint256 _reportID) internal {
        Violation[] memory listViolations = reports[_reportID].listViolations;

        uint256 numberOfViolations = listViolations.length;
        for (uint256 i = 0; i < numberOfViolations; i++) {
            violationsForValidator[listViolations[i].validatorIdentifier].push(
                listViolations[i]
            );
        }
    }

    /****************************************
     *         PROPOSER FUNCTIONS           *
     ****************************************/

    /// @notice Proposer creates a new report.
    /// @param _fromEpoch Starting epoch of the report on the Beacon Chain.
    /// @param _toEpoch Ending epoch of the report on the Beacon Chain.
    /// @param _listViolations List of the violations reported.
    function postReport(
        uint32 _fromEpoch,
        uint32 _toEpoch,
        Violation[] memory _listViolations
    ) public onlyApprovedProposer {
        reportID.increment();
        uint256 newReportID = reportID.current();

        settleReports();

        uint256 numberOfViolations = _listViolations.length;
        for (uint256 i = 0; i < numberOfViolations; i++) {
            validatorInReport[newReportID][
                _listViolations[i].validatorIdentifier
            ] = true;
            reports[newReportID].listViolations.push(_listViolations[i]);
        }

        reports[newReportID].fromEpoch = _fromEpoch;
        reports[newReportID].toEpoch = _toEpoch;

        bondCurrency.safeIncreaseAllowance(address(OO), bondAmount);

        reports[newReportID].assertionID = OO.assertTruth(
            Utils.toBytes(newReportID),
            address(this),
            address(0),
            address(0),
            challengeWindow,
            bondCurrency,
            bondAmount,
            priceIdentifier,
            ""
        );

        pendingReportsID.push(newReportID);
        emit reportMade(newReportID);
    }

    /****************************************
     *            STADER GETTERS            *
     ****************************************/

    /// @notice Get the all the finalized violations reported for a validator.
    /// @param _validatorIdentifier The Validator to get violations for.
    function getViolationsForValidator(
        bytes32 _validatorIdentifier
    ) external returns (Violation[] memory) {
        settleReports();
        return violationsForValidator[_validatorIdentifier];
    }

    /// @notice Get if a validator is concerned by a un-finalized report.
    /// @param _validatorIdentifier The Validator to check.
    function isValidatorInDispute(
        bytes32 _validatorIdentifier
    ) external returns (bool) {
        settleReports();

        uint256 numberOfPendingReports = pendingReportsID.length;
        for (uint256 i = 0; i < numberOfPendingReports; i++) {
            if (validatorInReport[pendingReportsID[i]][_validatorIdentifier]) {
                return true;
            }
        }

        uint256 numberOfDisputedReports = disputedReportsID.length;
        for (uint256 i = 0; i < numberOfDisputedReports; i++) {
            if (validatorInReport[disputedReportsID[i]][_validatorIdentifier]) {
                return true;
            }
        }

        return false;
    }

    /****************************************
     *            VIEW FUNCTIONS            *
     ****************************************/

    /// @notice Get the number of verified violations for a validator.
    /// @dev This is a view function that will not settle pending reports. It might not reflect latest reports.
    /// @dev It's usage on-chain is not recommended.
    /// @param _validatorIdentifier The Validator to check for.
    function numberOfViolationsForValidator(
        bytes32 _validatorIdentifier
    ) public view returns (uint256 len) {
        len = violationsForValidator[_validatorIdentifier].length;
    }

    /// @notice Get the violations contained in a report.
    /// @param _reportID The report to check for.
    function getViolationsInReport(
        uint256 _reportID
    ) public view returns (Violation[] memory containedViolation) {
        containedViolation = reports[_reportID].listViolations;
    }

    /**
     * @notice Computes the public key root.
     * @param _pubkey The validator public key for which to compute the root.
     * @return The root of the public key.
     */
    function getPubkeyRoot(
        bytes calldata _pubkey
    ) public pure returns (bytes32) {
        // Append 16 bytes of zero padding to the pubkey and compute its hash to get the pubkey root.
        return sha256(abi.encodePacked(_pubkey, bytes16(0)));
    }
}
