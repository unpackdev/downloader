// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract PsyBotAffiliate is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /* ===== CONSTANTS ===== */

    // PAYMENT_CONTRACT_ROLE should be granted to PsyBotSaleHelper after deployment
    bytes32 public constant PAYMENT_CONTRACT_ROLE =
        keccak256("PAYMENT_CONTRACT_ROLE");
    bytes32 public constant AFFILIATE_ADMIN_ROLE =
        keccak256("AFFILIATE_ADMIN_ROLE");
    bytes32 public constant FINANCE_ADMIN_ROLE =
        keccak256("FINANCE_ADMIN_ROLE");
    bytes32 public constant TIERS_ADMIN_ROLE = keccak256("TIERS_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // precision for percentage
    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    // affiliate tier => percnatage of revenue for the affiliate
    mapping(uint256 => uint256) public tierRevenuePercentages;
    // account => affiliate tier, 0 means account is not an affiliate.
    mapping (address => uint256) public affiliateTiers;

    // affiliate => claimable amount
    mapping(address => uint256) public affiliateAmounts;

    // Default 5% affiliate tier number.
    uint256 public defaultTier;
    // Number of affiliate tiers added to the contract. If this count is 2, for
    // example, then this contract currently has tier 1 and tier 2.
    uint256 public tierCount;

    /* ===== EVENTS ===== */

    event AffiliateClaimed(
        address indexed affiliate,
        uint256 amount
    );
    event AffiliateAmountIncreased(
        address indexed affiliate,
        uint256 amountIncreasedBy
    );
    event AffiliateFundsExtracted(
        address indexed affiliate,
        address indexed operator,
        uint256 amount
    );
    event FundsExtracted(
        address indexed operator,
        uint256 amount
    );
    event AffiliateTierAdded(
        uint256 indexed affiliateTier,
        uint256 newRevenuePercentage
    );
    event AffiliateTierUpdated(
        uint256 indexed affiliateTier,
        uint256 newRevenuePercentage
    );
    event AffiliateAdded(address indexed affiliate, uint256 affiliateTier);
    event AffiliateUpdated(address indexed affiliate, uint256 affiliateTier);
    event DefaultTierUpdated(uint256 indexed newDefaultTier);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256[] calldata _tierRevenuePercenages
    ) public initializer {
        defaultTier = 1;
        tierCount = _tierRevenuePercenages.length;

        for (uint256 i = 0; i < tierCount; i++) {
            tierRevenuePercentages[i + 1] = _tierRevenuePercenages[i];
        }

        _pause();

        address msgSender = _msgSender();
        _grantRole(AFFILIATE_ADMIN_ROLE, msgSender);
        _grantRole(FINANCE_ADMIN_ROLE, msgSender);
        _grantRole(TIERS_ADMIN_ROLE, msgSender);
        _grantRole(PAUSER_ROLE, msgSender);
        _grantRole(UPGRADER_ROLE, msgSender);
        _grantRole(DEFAULT_ADMIN_ROLE, msgSender);
    }

    /* ===== VIEWABLE ===== */

    /**
    @dev Public view function to get the percentage of an affiliate.
    @param affiliate the address of the affiliate the percentage is being
        queried for
    */
    function affiliatePercentage(address affiliate)
        external
        view
        returns (uint256)
    {
        return tierRevenuePercentages[affiliateTiers[affiliate]];
    }

    /* ===== FUNCTIONALITY ===== */

    /**
    @dev Anyone can call this to make themselves a default tier affiliate
    */
    function registerAsAfiliate() external whenNotPaused {
        address affiliate = _msgSender();

        require(
            affiliateTiers[affiliate] == 0,
            "PsyBotAffiliate: affiliate is already registered"
        );

        affiliateTiers[affiliate] = defaultTier;

        emit AffiliateAdded(affiliate, defaultTier);
    }

    /**
    @dev Function for affiliates to claim their cut of their affiliate partners
        payments.
    */
    function affiliateClaim() external whenNotPaused {
        address payable affiliate = payable(_msgSender());

        uint256 claimAmount = affiliateAmounts[affiliate];
        affiliateAmounts[affiliate] = 0;

        require(claimAmount > 0, "PsyBotAffiliate: nothing to claim");

        affiliate.transfer(claimAmount);

        emit AffiliateClaimed(affiliate, claimAmount);
    }

    /**
    @dev Function for the payment smart contract to invoke whenever someone
        some part of revenue goes to an affiliate.
    @param affiliate the address of the affiliate receiving funds
    */
    function increaseAffiliateAmount(address affiliate)
        external
        payable
        onlyRole(PAYMENT_CONTRACT_ROLE)
    {
        require(
            affiliateTiers[affiliate] != 0,
            "PsyBotAffiliate: affiliate is not registered"
        );

        uint256 amount = msg.value;
        require(amount > 0, "PsyBotAffiliate: zero amount");

        affiliateAmounts[affiliate] += amount;

        emit AffiliateAmountIncreased(affiliate, amount);
    }

    /**
    @dev Affiliate admin only function to register others as an affiliate with
        a requested tier
    @param affiliate the address of the affiliate
    @param tier the tier of the affiliate that determines the percentage of
        transfer fees they get
    */
    function addAffiliate(
        address affiliate,
        uint256 tier
    ) external onlyRole(AFFILIATE_ADMIN_ROLE) {
        require(affiliate != address(0), "PsyBotAffiliate: zero address");
        require(
            affiliateTiers[affiliate] == 0,
            "PsyBotAffiliate: affiliate is already registered"
        );
        require(
            tierRevenuePercentages[tier] > 0,
            "PsyBotAffiliate: tier doesn't exist"
        );

        affiliateTiers[affiliate] = tier;

        emit AffiliateAdded(affiliate, tier);
    }

    /**
    @dev Affiliate admin only function to update an affiliate tier (or remove
        the affiliate by updating their tier to 0)
    @param affiliate the address of the affiliate
    @param tier the tier of the affiliate that determines the percentage of
        transfer fees they get. 0 for affiliate removal
    */
    function updateAffiliate(
        address affiliate,
        uint256 tier
    ) external onlyRole(AFFILIATE_ADMIN_ROLE) {
        require(
            affiliateTiers[affiliate] != 0,
            "PsyBotAffiliate: affiliate is not registered"
        );
        require(
            tier == 0 || tierRevenuePercentages[tier] > 0,
            "PsyBotAffiliate: tier doesn't exist"
        );
        affiliateTiers[affiliate] = tier;

        emit AffiliateUpdated(affiliate, tier);
    }

    /* ===== MUTATIVE ===== */

    /**
    @dev Tiers admin only function to change the default affiliate tier used
        when someone registers themselves as an affiliate.
    @param newDefaultTier the new default affiliate tier, which has to be a
        valid tier above 0%
    */
    function updateDefaultTier(uint256 newDefaultTier)
        external
        onlyRole(TIERS_ADMIN_ROLE)
    {
        require(
            tierRevenuePercentages[newDefaultTier] > 0,
            "PsyBotAffiliate: tier doesn't exist"
        );

        defaultTier = newDefaultTier;

        emit DefaultTierUpdated(newDefaultTier);
    }

    /**
    @dev Tiers admin only function to add a tier.
    @param revenuePercentage the revenue percentage for the tier being added
        or updated
    */
    function addTier(uint256 revenuePercentage)
        external
        onlyRole(TIERS_ADMIN_ROLE)
    {
        require(
            revenuePercentage <= PRECISION,
            "PsyBotAffiliate: invalid percentage"
        );

        tierCount += 1;
        tierRevenuePercentages[tierCount] = revenuePercentage;

        emit AffiliateTierAdded(tierCount, revenuePercentage);
    }

    /**
    @dev Tiers admin only function to update a tier.
    @param tier the index for the tier mapping that is being updated
    @param revenuePercentage the percentage for the tier being updated
    */
    function updateTier(
        uint256 tier,
        uint256 revenuePercentage
    ) external onlyRole(TIERS_ADMIN_ROLE) {
        require(
            tier > 0 && tier <= tierCount,
            "PsyBotAffiliate: invalid tier"
        );
        require(
            revenuePercentage <= PRECISION,
            "PsyBotAffiliate: invalid percentage"
        );

        tierRevenuePercentages[tier] = revenuePercentage;

        emit AffiliateTierUpdated(tier, revenuePercentage);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
    @dev Finance admin only function to extract affiliate funds in case of an
        emergency (i.e. an affiliate needs their funds but can't claim for some
        reason).
    * this function will take away affiliate funds and should only be used for
        very specific cases
    @param affiliate the affiliate whose funds to extract
    */
    function extractAffiliateFunds(address affiliate) external onlyRole(FINANCE_ADMIN_ROLE) {
        address payable msgSender = payable(_msgSender());

        uint256 amountToExtract = affiliateAmounts[affiliate];
        affiliateAmounts[affiliate] = 0;

        require(amountToExtract > 0, "PsyBotAffiliate: nothing to extract");

        msgSender.transfer(amountToExtract);

        emit AffiliateFundsExtracted(
            affiliate,
            msgSender,
            amountToExtract
        );
    }

    /* ===== EMERGENCY ===== */

    /**
    @dev Finance admin only function to extract funds in case of an emergency
        (i.e. funds were accidentaly sent to the contract).
    * this function may take away affiliate funds and should only be used for
        very specific cases
    @param amount the amount of ERC20 token to extract from the contract
    @param useAmount boolean to determine if the amount should be used. If
        false, just extract currency balance from the contract.
    */
    function extractFunds(
        uint256 amount,
        bool useAmount
    ) external onlyRole(FINANCE_ADMIN_ROLE) {
        address payable msgSender = payable(_msgSender());
        uint256 amountToExtract;

        if (useAmount) {
            amountToExtract = amount;
        } else {
            amountToExtract = address(this).balance;
        }

        require(amountToExtract > 0, "PsyBotAffiliate: nothing to extract");

        msgSender.transfer(amountToExtract);

        emit FundsExtracted(msgSender, amountToExtract);
    }

    /* ===== INTERNAL ===== */

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
