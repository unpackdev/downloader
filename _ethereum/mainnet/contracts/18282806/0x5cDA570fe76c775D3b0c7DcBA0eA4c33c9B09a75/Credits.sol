// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract CreditBuy is
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    /// @notice Payment Token Address, used to buy credits.
    IERC20Upgradeable public paymentToken;

    /// @notice Address to receive paymentTokens from credit purchases.
    address public paymentWallet;

    /// @notice Total available plans for buying credits(active + inactive)
    uint256 public creditBuyPlansAvailable;

    struct CreditBuyPlan {
        uint256 credits;
        uint256 paymentTokensRequired;
        bool isActive;
    }

    // Mapping credit buy plan id => plan struct
    mapping(uint256 => CreditBuyPlan) public creditBuyPlans;

    // Event for users buying credits with paymentToken.
    event CreditsBought(
        address indexed by,
        uint256 indexed creditBuyPlan,
        uint256 creditsBought,
        uint256 paymentTokenAmount,
        uint256 timestamp
    );

    // Events for activating, deactivating, updating an existing CreditBuyPlan and for adding a new one.
    event ActivatedCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event DeactivatedCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event UpdatedCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 credits,
        uint256 paymentTokenRequired,
        uint256 timestamp
    );

    event AddedNewCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 credits,
        uint256 paymentTokenRequired,
        bool isActivated,
        uint256 timestamp
    );

    event PaymentWalletUpdated(
        address indexed by,
        address indexed oldPaymentWallet,
        address indexed newPaymentWallet,
        uint256 timestamp
    );

    /// @dev msg.sender must be contract owner or have DEFAULT_ADMIN_ROLE.
    modifier onlyAdminOrOwner() {
        require(
            msg.sender == owner() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin/owner."
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the contract.
     * @param _paymentToken Address of payment token to be used to buy credits.
     * @param _adminWallet Address of the account to be given the DEFAULT_ADMIN_ROLE.
     * @param _creditBuyPlans Credit Buy Plans with which contract is to be initialized.
     */
    function initialize(
        address _paymentToken,
        address _adminWallet,
        address _paymentWallet,
        CreditBuyPlan[] memory _creditBuyPlans
    ) external initializer {
        require(
            _paymentToken != address(0) &&
                _adminWallet != address(0) &&
                _paymentWallet != address(0),
            "Null address."
        );

        __AccessControl_init();
        __Ownable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        paymentToken = IERC20Upgradeable(_paymentToken);
        paymentWallet = _paymentWallet;
        addNewCreditBuyPlans(_creditBuyPlans);

        emit PaymentWalletUpdated(
            msg.sender,
            address(0),
            _paymentWallet,
            block.timestamp
        );
    }

    /**
     * @notice Function to buy credits with paymenttokens.
     * @dev Needs paymentToken allowance from buyer.
     * @param _planId Id of the available credit plan that user wants to buy.
     */
    function buyCredits(uint256 _planId) external {
        // Plan must be valid.
        require(
            _planId != 0 && _planId <= creditBuyPlansAvailable,
            "Invalid plan id."
        );

        // Retrieve buy plan details for given id.
        CreditBuyPlan memory plan = creditBuyPlans[_planId];

        // Plan must be active.
        require(plan.isActive, "Plan inactive.");

        // This contract should have sufficient paymentToken allowance from msg.sender.
        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                plan.paymentTokensRequired,
            "Insufficient paymentToken allowance."
        );

        // Emit CreditsBought event.
        emit CreditsBought(
            msg.sender,
            _planId,
            plan.credits,
            plan.paymentTokensRequired,
            block.timestamp
        );

        // Transfer paymentTokens from msg.sender to the paymentWallet.
        require(
            paymentToken.transferFrom(
                msg.sender,
                paymentWallet,
                plan.paymentTokensRequired
            ),
            "Error in transferring payment tokens."
        );
    }

    /**
     * @notice Batch function for owner/admin to activate multiple credit buy plans at once.
     * @param _planIds An array of plan ids to be activated.
     */
    function batchActivateCreditBuyPlans(
        uint256[] memory _planIds
    ) external onlyAdminOrOwner {
        for (uint256 i = 0; i < _planIds.length; i++) {
            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= creditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Activate the plan id.
            creditBuyPlans[planId].isActive = true;
        }

        emit ActivatedCreditBuyPlans(msg.sender, _planIds, block.timestamp);
    }

    /**
     * @notice Batch function for owner/admin to deactivate multiple credit buy plans at once.
     * @param _planIds An array of plan ids to be deactivated.
     */
    function batchDeactivateCreditBuyPlans(
        uint256[] memory _planIds
    ) external onlyAdminOrOwner {
        for (uint256 i = 0; i < _planIds.length; i++) {
            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= creditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Deactivate the plan id.
            creditBuyPlans[planId].isActive = false;
        }

        emit DeactivatedCreditBuyPlans(msg.sender, _planIds, block.timestamp);
    }

    /**
     * @notice Function for owner/admin to update an existing credit buy plan.
     * @param _planId Id of the credit buy plan to be updated.
     * @param _credits New value of credits for this plan.
     * @param _paymentTokensRequired New value of payment tokens required to buy this plan.
     */
    function updateCreditBuyPlan(
        uint256 _planId,
        uint256 _credits,
        uint256 _paymentTokensRequired
    ) external onlyAdminOrOwner {
        // _planId should be valid.
        require(
            _planId != 0 && _planId <= creditBuyPlansAvailable,
            "Invalid plan id."
        );

        // _credits and _paymentTokensRequired values must be greater than 0.
        require(_credits > 0 && _paymentTokensRequired > 0, "Cannot be zero.");

        // Read the plan from storage.
        CreditBuyPlan storage plan = creditBuyPlans[_planId];

        // Update the plan.
        plan.credits = _credits;
        plan.paymentTokensRequired = _paymentTokensRequired;

        emit UpdatedCreditBuyPlan(
            msg.sender,
            _planId,
            _credits,
            _paymentTokensRequired,
            block.timestamp
        );
    }

    /**
     * @notice Function for owner/admin to add new credit buy plans.
     * @param _creditBuyPlans New credit buy plans to be added.
     */
    function addNewCreditBuyPlans(
        CreditBuyPlan[] memory _creditBuyPlans
    ) public onlyAdminOrOwner {
        uint256 totalPlans = creditBuyPlansAvailable;

        for (uint256 i = 0; i < _creditBuyPlans.length; i++) {
            require(
                _creditBuyPlans[i].credits > 0,
                "Credits for plan cannot be 0."
            );
            require(
                _creditBuyPlans[i].paymentTokensRequired > 0,
                "Payment token required for plan cannot be 0."
            );

            // Increment local variable for total plans count, and store the new plan in storage.
            totalPlans += 1;
            creditBuyPlans[totalPlans] = _creditBuyPlans[i];

            emit AddedNewCreditBuyPlan(
                msg.sender,
                totalPlans,
                _creditBuyPlans[i].credits,
                _creditBuyPlans[i].paymentTokensRequired,
                _creditBuyPlans[i].isActive,
                block.timestamp
            );
        }

        // Set creditBuyPlansAvailable equal to totalPlans.
        creditBuyPlansAvailable = totalPlans;
    }

    /**
     * @notice Function for owner to update the payment wallet address.
     * @param _paymentWallet Address to be the new paymentWallet.
     */
    function updatePaymentWallet(address _paymentWallet) external onlyOwner {
        require(_paymentWallet != address(0), "Zero address provided!");
        address oldPaymentWallet = paymentWallet;
        paymentWallet = _paymentWallet;

        emit PaymentWalletUpdated(
            msg.sender,
            oldPaymentWallet,
            _paymentWallet,
            block.timestamp
        );
    }

    /**
     * @notice Returns details of all the credit buy plans available.
     */
    function getAllCreditBuyPlans()
        external
        view
        returns (CreditBuyPlan[] memory)
    {
        uint256 totalPlans = creditBuyPlansAvailable;
        CreditBuyPlan[] memory plans = new CreditBuyPlan[](totalPlans);

        for (uint256 i = 0; i < totalPlans; i++) {
            plans[i] = creditBuyPlans[i + 1];
        }
        return plans;
    }
}
