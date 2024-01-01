//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermController.sol";
import "./ITermEventEmitter.sol";
import "./TermAuctionGroup.sol";
import "./TermContractGroup.sol";
import "./TermAuction.sol";
import "./TermAuctionBidLocker.sol";
import "./TermAuctionOfferLocker.sol";
import "./TermPriceConsumerV3.sol";
import "./TermRepoCollateralManager.sol";
import "./TermRepoLocker.sol";
import "./TermRepoRolloverManager.sol";
import "./TermRepoServicer.sol";
import "./TermRepoToken.sol";
import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./Versionable.sol";

/// @author TermLabs
/// @title Term Initializer
/// @notice This contract provides utility methods for initializing/pairing a set of term/auction contracts
/// @dev This contract operates at the protocol level and provides utility functions for deploying terms/auctions
contract TermInitializer is AccessControlUpgradeable, Versionable {
    // ========================================================================
    // = Errors ===============================================================
    // ========================================================================

    error DeployingPaused();

    // ========================================================================
    // = Access Roles =========================================================
    // ========================================================================

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    bytes32 public constant INITIALIZER_APPROVAL_ROLE =
        keccak256("INITIALIZER_APPROVAL_ROLE");
    bytes32 public constant DEVOPS_ROLE = keccak256("DEVOPS_ROLE");

    // ========================================================================
    // = State Variables ======================================================
    // ========================================================================

    ITermController internal controller;
    ITermEventEmitter internal emitter;
    TermPriceConsumerV3 internal priceOracle;
    bool internal deployingPaused;

    // ========================================================================
    // = Modifiers  ===========================================================
    // ========================================================================

    modifier whileDeployingNotPaused() {
        if (deployingPaused) {
            revert DeployingPaused();
        }
        _;
    }

    // ========================================================================
    // = Initialize (https://docs.openzeppelin.com/contracts/4.x/upgradeable) =
    // ========================================================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address initializerApprovalRole_, address devopsWallet_) {
        _grantRole(DEVOPS_ROLE, devopsWallet_);
        _grantRole(INITIALIZER_APPROVAL_ROLE, initializerApprovalRole_);
        _grantRole(DEPLOYER_ROLE, msg.sender);
        deployingPaused = false;
    }

    function pairTermContracts(
        ITermController controller_,
        ITermEventEmitter emitter_,
        TermPriceConsumerV3 priceOracle_
    ) external onlyRole(DEPLOYER_ROLE) {
        controller = controller_;
        emitter = emitter_;
        priceOracle = priceOracle_;
    }

    // ========================================================================
    // = Interface/API ========================================================
    // ========================================================================

    /// @notice Sets up a set of deployed term contracts
    function setupTerm(
        TermContractGroup calldata termContractGroup,
        address devOpsMultiSig,
        address adminWallet,
        string memory termVersion,
        string memory auctionVersion
    ) external onlyRole(INITIALIZER_APPROVAL_ROLE) whileDeployingNotPaused {
        require(
            controller.isTermDeployed(
                address(termContractGroup.termRepoServicer)
            ),
            "Non-Term TRS"
        );
        require(
            controller.isTermDeployed(
                address(termContractGroup.termRepoCollateralManager)
            ),
            "Non-Term TRCM"
        );
        require(
            controller.isTermDeployed(
                address(termContractGroup.termRepoLocker)
            ),
            "Non-Term TRL"
        );
        require(
            controller.isTermDeployed(address(termContractGroup.termRepoToken)),
            "Non-Term TRT"
        );
        require(
            controller.isTermDeployed(
                address(termContractGroup.rolloverManager)
            ),
            "Non-Term TRM"
        );

        require(
            controller.isTermDeployed(
                address(termContractGroup.termAuctionBidLocker)
            ),
            "Non-Term TABL"
        );
        require(
            controller.isTermDeployed(
                address(termContractGroup.termAuctionOfferLocker)
            ),
            "Non-Term TAOL"
        );
        require(
            controller.isTermDeployed(address(termContractGroup.auction)),
            "Non-Term TA"
        );

        emitter.pairTermContract(address(termContractGroup.termRepoLocker));

        termContractGroup.termRepoLocker.pairTermContracts(
            address(termContractGroup.termRepoCollateralManager),
            address(termContractGroup.termRepoServicer),
            emitter,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(address(termContractGroup.termRepoToken));
        termContractGroup.termRepoToken.pairTermContracts(
            address(termContractGroup.termRepoServicer),
            emitter,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(
            address(termContractGroup.termAuctionBidLocker)
        );
        termContractGroup.termAuctionBidLocker.pairTermContracts(
            address(termContractGroup.auction),
            termContractGroup.termRepoServicer,
            emitter,
            termContractGroup.termRepoCollateralManager,
            priceOracle,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(
            address(termContractGroup.termAuctionOfferLocker)
        );
        termContractGroup.termAuctionOfferLocker.pairTermContracts(
            address(termContractGroup.auction),
            emitter,
            termContractGroup.termRepoServicer,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(address(termContractGroup.auction));
        termContractGroup.auction.pairTermContracts(
            emitter,
            termContractGroup.termRepoServicer,
            termContractGroup.termAuctionBidLocker,
            termContractGroup.termAuctionOfferLocker,
            devOpsMultiSig,
            adminWallet,
            auctionVersion
        );

        emitter.pairTermContract(address(termContractGroup.termRepoServicer));
        termContractGroup.termRepoServicer.pairTermContracts(
            address(termContractGroup.termRepoLocker),
            address(termContractGroup.termRepoCollateralManager),
            address(termContractGroup.termRepoToken),
            address(termContractGroup.termAuctionOfferLocker),
            address(termContractGroup.auction),
            address(termContractGroup.rolloverManager),
            devOpsMultiSig,
            adminWallet,
            termVersion
        );

        emitter.pairTermContract(
            address(termContractGroup.termRepoCollateralManager)
        );
        termContractGroup.termRepoCollateralManager.pairTermContracts(
            address(termContractGroup.termRepoLocker),
            address(termContractGroup.termRepoServicer),
            address(termContractGroup.termAuctionBidLocker),
            address(termContractGroup.auction),
            address(controller),
            address(priceOracle),
            address(termContractGroup.rolloverManager),
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(address(termContractGroup.rolloverManager));
        termContractGroup.rolloverManager.pairTermContracts(
            address(termContractGroup.termRepoServicer),
            emitter,
            devOpsMultiSig,
            adminWallet
        );
    }

    /// @notice Sets up a set of deployed term contracts
    function setupAuction(
        TermRepoServicer termRepoServicer,
        TermRepoCollateralManager termRepoCollateralManager,
        TermAuctionOfferLocker termAuctionOfferLocker,
        TermAuctionBidLocker termAuctionBidLocker,
        TermAuction auction,
        address devOpsMultiSig,
        address adminWallet,
        string calldata auctionVersion
    ) external onlyRole(INITIALIZER_APPROVAL_ROLE) whileDeployingNotPaused {
        require(
            controller.isTermDeployed(address(termRepoServicer)),
            "Non-Term TRS"
        );
        require(
            controller.isTermDeployed(address(termRepoCollateralManager)),
            "Non-Term TRCM"
        );

        require(
            controller.isTermDeployed(address(termAuctionBidLocker)),
            "Non-Term TABL"
        );
        require(
            controller.isTermDeployed(address(termAuctionOfferLocker)),
            "Non-Term TAOL"
        );
        require(controller.isTermDeployed(address(auction)), "Non-Term TA");

        emitter.pairTermContract(address(termAuctionBidLocker));
        termAuctionBidLocker.pairTermContracts(
            address(auction),
            termRepoServicer,
            emitter,
            termRepoCollateralManager,
            priceOracle,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(address(termAuctionOfferLocker));
        termAuctionOfferLocker.pairTermContracts(
            address(auction),
            emitter,
            termRepoServicer,
            devOpsMultiSig,
            adminWallet
        );

        emitter.pairTermContract(address(auction));
        auction.pairTermContracts(
            emitter,
            termRepoServicer,
            termAuctionBidLocker,
            termAuctionOfferLocker,
            devOpsMultiSig,
            adminWallet,
            auctionVersion
        );

        termRepoCollateralManager.reopenToNewAuction(
            TermAuctionGroup({
                auction: auction,
                termAuctionBidLocker: termAuctionBidLocker,
                termAuctionOfferLocker: termAuctionOfferLocker
            })
        );

        termRepoServicer.reopenToNewAuction(
            TermAuctionGroup({
                auction: auction,
                termAuctionBidLocker: termAuctionBidLocker,
                termAuctionOfferLocker: termAuctionOfferLocker
            })
        );
    }

    // ========================================================================
    // = Pause Functions ======================================================
    // ========================================================================

    function pauseDeploying() external onlyRole(DEVOPS_ROLE) {
        deployingPaused = true;
    }

    function unpauseDeploying() external onlyRole(DEVOPS_ROLE) {
        deployingPaused = false;
    }
}
