//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./ITermAuctionBidLocker.sol";
import "./ITermAuctionOfferLocker.sol";
import "./ITermEventEmitter.sol";
import "./ITermRepoRolloverManager.sol";
import "./ITermRepoRolloverManagerErrors.sol";
import "./ITermRepoCollateralManager.sol";
import "./ITermRepoServicer.sol";
import "./ITermController.sol";
import "./ExponentialNoError.sol";
import "./TermAuctionBid.sol";
import "./TermRepoRolloverElection.sol";
import "./TermRepoRolloverElectionSubmission.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Versionable.sol";

/// @author TermLabs
/// @title Term Repo Rollover Manager
/// @notice This contract accepts and carries out borrower Term Repo rollover instructions
/// @dev This contract belongs to the Term Servicer group of contracts and is specific to a Term Repo deployment
contract TermRepoRolloverManager is
    ITermRepoRolloverManager,
    ITermRepoRolloverManagerErrors,
    ExponentialNoError,
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    Versionable
{
    // ========================================================================
    // = Access Role  =========================================================
    // ========================================================================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DEVOPS_ROLE = keccak256("DEVOPS_ROLE");
    bytes32 public constant INITIALIZER_ROLE = keccak256("INITIALIZER_ROLE");
    bytes32 public constant ROLLOVER_BID_FULFILLER_ROLE =
        keccak256("ROLLOVER_BID_FULFILLER_ROLE");

    // ========================================================================
    // = State Variables ======================================================
    // ========================================================================
    bytes32 public termRepoId;
    ITermRepoCollateralManager internal termRepoCollateralManager;
    ITermRepoServicer internal termRepoServicer;
    ITermController internal termController;
    ITermEventEmitter internal emitter;

    // Mapping that returns true for approved Borrower Rollover Auction Bid Lockers
    mapping(address => bool) internal approvedRolloverAuctionBidLockers;

    // Borrow Rollover Ledger
    // For each borrower wallet address, keep ledger of borrow rollver election addresses.
    mapping(address => TermRepoRolloverElection) internal rolloverElections;

    bool internal termContractPaired;

    // ========================================================================
    // = Modifiers ============================================================
    // ========================================================================

    modifier whileNotMatured() {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= termRepoServicer.maturityTimestamp()) {
            revert MaturityReached();
        }
        _;
    }

    modifier notTermContractPaired() {
        if (termContractPaired) {
            revert AlreadyTermContractPaired();
        }
        termContractPaired = true;
        _;
    }

    // ========================================================================
    // = Deploy  ==============================================================
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata termRepoId_,
        ITermRepoServicer termRepoServicer_,
        ITermRepoCollateralManager termRepoCollateralManager_,
        ITermController termController_,
        address termInitializer_
    ) external initializer {
        UUPSUpgradeable.__UUPSUpgradeable_init();
        AccessControlUpgradeable.__AccessControl_init();

        termRepoId = keccak256(abi.encodePacked(termRepoId_));
        termRepoCollateralManager = termRepoCollateralManager_;
        termRepoServicer = termRepoServicer_;
        termController = termController_;

        termContractPaired = false;

        _grantRole(INITIALIZER_ROLE, termInitializer_);
    }

    function pairTermContracts(
        address termRepoServicer_,
        ITermEventEmitter emitter_,
        address devopsMultisig_,
        address adminWallet_
    ) external onlyRole(INITIALIZER_ROLE) notTermContractPaired {
        emitter = emitter_;
        _grantRole(ROLLOVER_BID_FULFILLER_ROLE, termRepoServicer_);
        _grantRole(DEVOPS_ROLE, devopsMultisig_);
        _grantRole(ADMIN_ROLE, adminWallet_);

        emitter.emitTermRepoRolloverManagerInitialized(
            termRepoId,
            address(this)
        );
    }

    // ========================================================================
    // = APIs  ================================================================
    // ========================================================================

    /// @notice An external function that accepted Term Repo rollover instructions
    /// @param termRepoRolloverElectionSubmission A struct containing borrower rollover instructions
    function electRollover(
        TermRepoRolloverElectionSubmission
            calldata termRepoRolloverElectionSubmission
    ) external whileNotMatured {
        address borrower = msg.sender;
        uint256 borrowerRepurchaseObligation = termRepoServicer
            .getBorrowerRepurchaseObligation(borrower);
        if (borrowerRepurchaseObligation == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }
        if (
            !approvedRolloverAuctionBidLockers[
                termRepoRolloverElectionSubmission.rolloverAuctionBidLocker
            ]
        ) {
            revert RolloverAddressNotApproved(
                termRepoRolloverElectionSubmission.rolloverAuctionBidLocker
            );
        }

        if (rolloverElections[borrower].processed) {
            revert RolloverProcessedToTerm();
        }

        if (termRepoRolloverElectionSubmission.rolloverAmount == 0) {
            revert InvalidParameters("Rollover amount cannot be 0");
        }

        if (
            borrowerRepurchaseObligation <
            termRepoRolloverElectionSubmission.rolloverAmount
        ) {
            revert BorrowerRepurchaseObligationInsufficient();
        }

        if(rolloverElections[borrower].rolloverAuctionBidLocker != address(0) && rolloverElections[borrower].rolloverAuctionBidLocker != termRepoRolloverElectionSubmission.rolloverAuctionBidLocker){
            rolloverElections[borrower].rolloverAmount = 0;
            _processRollover(borrower);
        }


        rolloverElections[borrower] = TermRepoRolloverElection({
            rolloverAuctionBidLocker: termRepoRolloverElectionSubmission.rolloverAuctionBidLocker,
            rolloverAmount: termRepoRolloverElectionSubmission.rolloverAmount,
            rolloverBidPriceHash: termRepoRolloverElectionSubmission
                .rolloverBidPriceHash,
            processed: false
        });

        ITermAuctionBidLocker auctionBidLocker = ITermAuctionBidLocker(
            termRepoRolloverElectionSubmission.rolloverAuctionBidLocker
        );

        emitter.emitRolloverElection(
            termRepoId,
            auctionBidLocker.termRepoId(),
            borrower,
            termRepoRolloverElectionSubmission.rolloverAuctionBidLocker,
            termRepoRolloverElectionSubmission.rolloverAmount,
            termRepoRolloverElectionSubmission.rolloverBidPriceHash
        );

        _processRollover(borrower);
    }

    /// @notice A view function that returns borrower rollover instructions
    /// @param borrower The address of the borrower
    /// @return A struct containing borrower rollover instructions
    function getRolloverInstructions(
        address borrower
    ) external view returns (TermRepoRolloverElection memory) {
        return rolloverElections[borrower];
    }

    /// @notice An external function to cancel previously submitted rollover instructions
    function cancelRollover() external {
        address borrower = msg.sender;
        if (termRepoServicer.getBorrowerRepurchaseObligation(borrower) == 0) {
            revert ZeroBorrowerRepurchaseObligation();
        }

        if (rolloverElections[borrower].rolloverAmount == 0) {
            revert NoRolloverToCancel();
        }

        if (rolloverElections[borrower].processed) {
            revert RolloverProcessedToTerm();
        }

        rolloverElections[borrower].rolloverAmount = 0;

        _processRollover(borrower);

        delete rolloverElections[borrower];

        emitter.emitRolloverCancellation(termRepoId, borrower);
    }

    // ========================================================================
    // = Fulfiller Functions ================================================
    // ========================================================================

    /// @notice An external function called by repo servicer to mark rollover as fulfilled
    /// @param borrower The address of the borrower
    function fulfillRollover(
        address borrower
    ) external onlyRole(ROLLOVER_BID_FULFILLER_ROLE) {
        rolloverElections[borrower].processed = true;
        emitter.emitRolloverProcessed(termRepoId, borrower);
    }

    // ========================================================================
    // = Admin Functions ======================================================
    // ========================================================================

    /// @param auctionBidLocker The ABI for ITermAuctionBidLocker interface
    function approveRolloverAuction(
        ITermAuctionBidLocker auctionBidLocker
    ) external onlyRole(ADMIN_ROLE) {
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp >= termRepoServicer.maturityTimestamp()) {
            revert MaturityReached();
        }
        if (!termController.isTermDeployed(address(auctionBidLocker))) {
            revert NotTermContract(address(auctionBidLocker));
        }

        if (
            auctionBidLocker.auctionEndTime() >
            termRepoServicer.endOfRepurchaseWindow()
        ) {
            revert AuctionEndsAfterRepayment();
        }
        if (
            auctionBidLocker.auctionEndTime() <
            termRepoServicer.maturityTimestamp()
        ) {
            revert AuctionEndsBeforeMaturity();
        }
        if (
            termRepoServicer.purchaseToken() !=
            address(auctionBidLocker.purchaseToken())
        ) {
            revert DifferentPurchaseToken(
                termRepoServicer.purchaseToken(),
                address(auctionBidLocker.purchaseToken())
            );
        }

        uint256 numOfAcceptedCollateralTokens = termRepoCollateralManager
            .numOfAcceptedCollateralTokens();

        for (uint256 i = 0; i < numOfAcceptedCollateralTokens; ++i) {
            IERC20Upgradeable supportedIERC20Collateral = IERC20Upgradeable(
                termRepoCollateralManager.collateralTokens(i)
            );
            if (!auctionBidLocker.collateralTokens(supportedIERC20Collateral)) {
                revert CollateralTokenNotSupported(
                    address(supportedIERC20Collateral)
                );
            }
        }

        approvedRolloverAuctionBidLockers[address(auctionBidLocker)] = true;

        address termAuction = address(auctionBidLocker.termAuction());

        termRepoServicer.approveRolloverAuction(termAuction);
        termRepoCollateralManager.approveRolloverAuction(termAuction);

        _grantRole(ROLLOVER_BID_FULFILLER_ROLE, termAuction);

        emitter.emitRolloverTermApproved(
            termRepoId,
            auctionBidLocker.termAuctionId()
        );
    }

    /// @param auctionBidLocker The ABI for ITermAuctionBidLocker interface
    function revokeRolloverApproval(
        ITermAuctionBidLocker auctionBidLocker
    ) external onlyRole(ADMIN_ROLE) {
        approvedRolloverAuctionBidLockers[address(auctionBidLocker)] = false;

        emitter.emitRolloverTermApprovalRevoked(
            termRepoId,
            auctionBidLocker.termAuctionId()
        );
    }

    // ========================================================================
    // = Internal =============================================================
    // ========================================================================

    function _processRollover(address borrowerToRollover) internal {
        TermRepoRolloverElection memory rolloverElection = rolloverElections[
            borrowerToRollover
        ];

        ITermAuctionBidLocker termAuctionBidLocker = ITermAuctionBidLocker(
            rolloverElection.rolloverAuctionBidLocker
        );

        ITermRepoServicer futureTermRepoServicer = termAuctionBidLocker
            .termRepoServicer();

        uint256 servicingFeeProRatedMantissa = mul_(
            Exp({mantissa: termAuctionBidLocker.dayCountFractionMantissa()}),
            Exp({mantissa: futureTermRepoServicer.servicingFee()})
        ).mantissa;

        uint256 bidAmount;

        if (rolloverElection.rolloverAmount > 0) {
            bidAmount = truncate(
                div_(
                    Exp({mantissa: rolloverElection.rolloverAmount * expScale}),
                    Exp({mantissa: expScale - servicingFeeProRatedMantissa})
                )
            );
        } else {
            bidAmount = 0;
        }

        (address[] memory collateralTokens, ) = termRepoCollateralManager
            .getCollateralBalances(borrowerToRollover);

        uint256[] memory collateralAmounts = new uint256[](
            collateralTokens.length
        );

        TermAuctionBid memory termAuctionBid = TermAuctionBid({
            id: keccak256(abi.encodePacked(address(this), borrowerToRollover)),
            bidder: borrowerToRollover,
            bidPriceHash: rolloverElection.rolloverBidPriceHash,
            bidPriceRevealed: 0,
            amount: bidAmount,
            collateralTokens: collateralTokens,
            collateralAmounts: collateralAmounts,
            purchaseToken: termRepoServicer.purchaseToken(),
            isRollover: true,
            rolloverPairOffTermRepoServicer: address(termRepoServicer),
            isRevealed: false
        });

        termAuctionBidLocker.lockRolloverBid(termAuctionBid);
    }

    ///@dev required override by the OpenZeppelin UUPS module
    ///@param impl new impl address for proxy upgrade
    function _authorizeUpgrade(
        address impl
    ) internal override onlyRole(DEVOPS_ROLE) {
        emitter.emitTermContractUpgraded(address(this), impl);
    }
}
