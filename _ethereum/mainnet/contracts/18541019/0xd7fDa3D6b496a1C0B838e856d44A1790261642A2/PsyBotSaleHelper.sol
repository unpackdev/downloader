// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./PsyBot.sol";
import "./PsyBotAffiliate.sol";

contract PsyBotSaleHelper is
    Initializable,
    AccessControlEnumerableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /* ===== CONSTANTS ===== */

    bytes32 public constant FINANCE_ADMIN_ROLE =
        keccak256("FINANCE_ADMIN_ROLE");
    bytes32 public constant COUPON_ADMIN_ROLE = keccak256("COUPON_ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant PRECISION = 10000;

    /* ===== GENERAL ===== */

    uint256 public price;
    uint256 public presalePrice;
    uint256 public presaleLimit;

    PsyBot public psyBot;
    PsyBotAffiliate public psyBotAffiliate;

    address payable public companyWallet;

    /* ===== EVENTS ===== */

    event NFTPurchase(
        address indexed purchaser,
        uint256 purchasePrice
    );

    event PriceSet(uint256 newPrice);
    event PresalePriceSet(uint256 newPrice);
    event PresaleLimitSet(uint256 newLimit);
    event CompanyWalletSet(address newCompanyWallet);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    // currencies are expected to have the same value and decimals
    function initialize(
        PsyBot _psyBot,
        PsyBotAffiliate _psyBotAffiliate,
        uint256 _price,
        uint256 _presalePrice,
        uint256 _presaleLimit
    ) public initializer {
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        require(
            address(_psyBot) != address(0) &&
                address(_psyBotAffiliate) != address(0),
            "PsyBotSaleHelper: zero address"
        );
        require(
            _psyBotAffiliate.PRECISION() == PRECISION,
            "PsyBotSaleHelper: invalid precision"
        );

        psyBot = _psyBot;
        psyBotAffiliate = _psyBotAffiliate;

        price = _price;
        presalePrice = _presalePrice;
        presaleLimit = _presaleLimit;

        _pause();

        address msgSender = _msgSender();

        companyWallet = payable(msgSender);

        _grantRole(DEFAULT_ADMIN_ROLE, msgSender);
        _grantRole(FINANCE_ADMIN_ROLE, msgSender);
        _grantRole(COUPON_ADMIN_ROLE, msgSender);
        _grantRole(PAUSER_ROLE, msgSender);
        _grantRole(UPGRADER_ROLE, msgSender);
    }

    /* ===== VIEWABLE ===== */

    function isPresalePriceAvailable() public view returns (bool) {
        return psyBot.totalSupply() < presaleLimit;
    }

    function getPurchasePrice() public view returns (uint256) {
        if (isPresalePriceAvailable()) {
            return presalePrice;
        } else {
            return price;
        }
    }

    /* ===== FUNCTIONALITY ===== */

    function purchase() external payable {
        _purchase(address(0));
    }

    function purchaseWithAffilliate(address affiliate) external payable {
        _purchase(affiliate);
    }

    /* ===== MUTATIVE ===== */

    function setPrice(uint256 newPrice) external onlyRole(FINANCE_ADMIN_ROLE) {
        price = newPrice;

        emit PriceSet(newPrice);
    }

    function setPresalePrice(uint256 newPrice)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        presalePrice = newPrice;

        emit PresalePriceSet(newPrice);
    }

    function setPresaleLimit(uint256 newLimit)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        presaleLimit = newLimit;

        emit PresaleLimitSet(newLimit);
    }

    function setCompanyWallet(address newCompanyWallet)
        external
        onlyRole(FINANCE_ADMIN_ROLE)
    {
        companyWallet = payable(newCompanyWallet);

        emit CompanyWalletSet(newCompanyWallet);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _purchase(address affiliate) private whenNotPaused {
        address purchaser = _msgSender();

        uint256 purchasePrice = getPurchasePrice();
        require(
            msg.value == purchasePrice,
            "PsyBotSaleHelper: invalid value sent"
        );

        uint256 affiliatePercentage = 0;
        if (affiliate != address(0)) {
            affiliatePercentage =
                psyBotAffiliate.affiliatePercentage(affiliate);
        }

        uint256 affiliateAmount =
                purchasePrice * affiliatePercentage / PRECISION;
        uint256 companyAmount = purchasePrice - affiliateAmount;

        companyWallet.transfer(companyAmount);

        if (affiliateAmount != 0) {
            psyBotAffiliate.increaseAffiliateAmount{value: affiliateAmount}(
                affiliate
            );
        }

        psyBot.mint(purchaser);

        emit NFTPurchase(purchaser, purchasePrice);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}
