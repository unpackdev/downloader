// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./ERC1155HolderUpgradeable.sol";

import "./IERC1155.sol";
import "./BaseUpgradeable.sol";
import "./PaymenProcessingUpgradeable.sol";
import "./PriceOracleUpgradeable.sol";

import "./FixedPointMathLib.sol";
import "./Constants.sol";

interface ILazyCollection {
    function isUsed(uint256 uid_) external view returns (bool);
}

interface IERC1155Supply {
    function totalSupply(uint256 id) external view returns (uint256);

    function totalMinted(uint256 id) external view returns (uint256);
}

interface ITokenSaleUpgradeable {
    struct Presale {
        uint64 startTime;
        uint64 endTime;
        uint64 nonce;
        uint64 maxBuy;
        uint128 tokenPrice;
        uint128 netPrice;
    }

    function erc1155Collection() external view returns (address);

    function isExchangeable(uint256 id) external view returns (bool);

    function buy(uint256 id_, uint256 quantity_, address paymentToken_, address recipient_, address referrer_) external payable;

    event TokensPurchased(address indexed purchaser, uint256 id, uint256 quantity, address paymentToken);
    event PreSaleInfo(uint256 id, uint256 tokenPrice, uint256 netPrice, uint256 maxSupply, uint256 maxBuy);

    error InvalidTimeRange();
    error InvalidPrice();
    error DisableBuying();
}

contract TokenSaleUpgradeable is ITokenSaleUpgradeable, BaseUpgradeable, ERC1155HolderUpgradeable, PriceOracleUpgradeable, ReentrancyGuardUpgradeable, PaymenProcessingUpgradeable {
    using FixedPointMathLib for uint256;

    mapping(uint256 => Presale) private _presaleDetails; // id => presaleInfo
    mapping(uint256 => uint256) private _tokensSold;

    address public erc721Collection;
    address public erc1155Collection;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address roleManager_,
        address erc721Collection_,
        address erc1155Collection_,
        uint256 id_,
        Presale calldata presaleInfo_,
        FeeInfo calldata clientInfo_,
        FeeInfo calldata systemInfo_,
        address paymentToken_,
        PriceFeed calldata priceFeed_
    ) public initializer {
        __ReentrancyGuard_init();
        __BaseUpgradeable_init(roleManager_);
        _setPresale(id_, presaleInfo_);
        _setCollection(erc721Collection_, erc1155Collection_);
        _setPriceFeeds(paymentToken_, priceFeed_);
        clientInfo = clientInfo_;
        systemInfo = systemInfo_;
    }

    function setCollection(address erc721Collection_, address erc1155Collection_) external onlyRole(OPERATOR_ROLE) {
        _setCollection(erc721Collection_, erc1155Collection_);
    }

    function setPresale(uint256 id_, Presale calldata presaleInfo_) external onlyRole(OPERATOR_ROLE) {
        if (presaleInfo_.tokenPrice == 0) revert InvalidPrice();

        if (presaleInfo_.endTime < presaleInfo_.startTime) revert InvalidTimeRange();

        if (presaleInfo_.maxBuy < _presaleDetails[id_].maxBuy) revert();

        _setPresale(id_, presaleInfo_);

        emit PreSaleInfo(id_, presaleInfo_.tokenPrice, presaleInfo_.netPrice, IERC1155Supply(erc1155Collection).totalMinted(id_), presaleInfo_.maxBuy);
    }

    function configPaymentPercentage(FeeInfo calldata clientInfo_, FeeInfo calldata systemInfo_, uint96 affiliatePercentageInBps_) external onlyRole(OPERATOR_ROLE) {
        if (clientInfo_.percentageInBps + systemInfo_.percentageInBps + affiliatePercentageInBps_ != HUNDER_PERCENT_IN_BPS) revert Payment__InvalidPercentage();
        clientInfo = clientInfo_;
        systemInfo = systemInfo_;
        affiliatePercentageInBps = affiliatePercentageInBps_;
    }

    function _setCollection(address erc721Collection_, address erc1155Collection_) internal {
        erc721Collection = erc721Collection_;
        erc1155Collection = erc1155Collection_;
    }

    function _setPresale(uint256 id_, Presale calldata presaleInfo_) internal {
        _presaleDetails[id_] = presaleInfo_;
    }

    function setPriceFeeds(address token_, PriceFeed memory priceFeed_) external onlyRole(OPERATOR_ROLE) {
        _setPriceFeeds(token_, priceFeed_);
    }

    function buy(uint256 id_, uint256 quantity_, address paymentToken_, address recipient_, address referrer_) external payable {
        if (ILazyCollection(erc721Collection).isUsed(_presaleDetails[id_].nonce)) revert DisableBuying();

        _buy(_msgSender(), id_, quantity_, paymentToken_, recipient_, referrer_);
    }

    function _buy(address sender_, uint256 id_, uint256 quantity_, address paymentToken_, address recipient_, address referrer_) internal {
        uint256 paymentAmount_ = _getTokenUsdAmount(paymentToken_, _presaleDetails[id_].tokenPrice * quantity_);
        uint256 netAmount_ = _getTokenUsdAmount(paymentToken_, _presaleDetails[id_].netPrice * quantity_);

        _tokensSold[id_] += quantity_;

        _processPayment(paymentToken_, paymentAmount_, netAmount_, sender_, referrer_);

        IERC1155(erc1155Collection).safeTransferFrom(address(this), recipient_, id_, quantity_, "0x");

        emit TokensPurchased(recipient_, id_, quantity_, paymentToken_);
    }

    function getPresaleInfo(uint256 id) external view returns (uint256 tokensSold, uint256 maxBuy, uint256 maxSupply, uint256 price, uint256 nonce) {
        Presale memory presaleInfo = _presaleDetails[id];

        return (_tokensSold[id], presaleInfo.maxBuy, IERC1155Supply(erc1155Collection).totalMinted(id), presaleInfo.tokenPrice, presaleInfo.nonce);
    }

    function getTokenPaymentAmount(uint256 id_, uint256 quantity_, address paymentToken_) external view returns (uint256) {
        uint256 tokenAmount = _getTokenUsdAmount(paymentToken_, _presaleDetails[id_].tokenPrice * quantity_);
        return tokenAmount;
    }

    function isExchangeable(uint256 id) external view returns (bool) {
        if (ILazyCollection(erc721Collection).isUsed(_presaleDetails[id].nonce)) return true;
        return false;
    }
}
