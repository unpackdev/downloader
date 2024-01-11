//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./EnumerableSet.sol";
import "./ERC721AQueryable.sol";

error PromoNotActive();
error RecipientIsNotEOA();
error SaleNotActive(uint256 timestamp);
error TPPPreviouslyMinted();
error MaxSupplyExceeded();
error MaxMintQuantityExceeded();
error IncorrectEtherValueSent(uint256 expectedValue);
error ValueUnchanged();
error InvalidValue();
error ExceedsAvailableAllowance(uint256 allowance);
error InvalidSignature();
error RefundsNotActive();
error ZeroRefundAvailable();
error NotTokenOwner();
error ContractFundsInsufficient();

contract OSOwnableDelegateProxy {}

contract OSProxyRegistry {
    mapping(address => OSOwnableDelegateProxy) public proxies;
}

/**
 * @notice A structure holding records of non-operator/admin transactions.
 *
 * @dev Definitions -
 *
 * promoRedemptions: Number of tokens minted via {ToonPals-mintPromo}
 * wlPurchases: Number of tokens minted via {ToonPals-mintWL}, a paid transaction
 * salePurchases: Number of tokens minted via {ToonPals-mint}, a paid transaction
 * refundQuantity: Number of tokens refunded and burned. Covers paid transactions
 *
 */
struct TransactionRecord {
    uint256 promoRedemptions;
    uint256 wlPurchases;
    uint256 salePurchases;
    uint256 refundQuantity;
}

/**
 * @title ToonPals
 *
 * @notice ERC-721 NFT Token Contract.
 * Includes support for promo minting, ToonPals Pass redemptions, WL & public sale.
 * Also supports refunds.
 *
 * Promo minting activation is based on number of tokens minted and is mutable.
 * Minting/sale activation is based on timestamp and is mutable.
 * Refund activation is based on an operator-gated function. See {ToonPals-setRefundsActive}.
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
contract ToonPals is
    ReentrancyGuard,
    Ownable,
    AccessControl,
    EIP712,
    ERC721AQueryable
{
    using Address for address payable;
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant WL_SIGNER_ROLE = keccak256("WL_SIGNER_ROLE");
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address account)");
    uint256 public constant maxSupply = 6969;
    uint256 public constant mintValue = 0.065 ether;
    uint256 public constant reservedPals = 100;

    uint256 public maxPromoMintQuantity = 1;
    uint256 public maxWLMintQuantity = 3;
    uint256 public maxMintQuantity = 5;
    uint256 public promoThreshold;
    bool public tppMinted;
    uint256 public wlActiveTimestamp;
    uint256 public saleActiveTimestamp;
    bool public refundsActive;
    string public baseURI;
    mapping(address => TransactionRecord) public transactionRecords;

    EnumerableSet.AddressSet internal _transactingAddresses;
    OSProxyRegistry internal _osProxyRegistry;

    event MaxPromoMintQuantityUpdated(
        uint256 oldMaxPromoMintQuantity,
        uint256 maxPromoMintQuantity
    );
    event MaxWLMintQuantityUpdated(
        uint256 oldMaxWLMintQuantity,
        uint256 maxWLMintQuantity
    );
    event MaxMintQuantityUpdated(
        uint256 oldMaxMintQuantity,
        uint256 maxMintQuantity
    );
    event PromoThresholdUpdated(
        uint256 oldPromoThreshold,
        uint256 promoThreshold
    );
    event WLActiveTimestampUpdated(
        uint256 oldWLActiveTimestamp,
        uint256 wlActiveTimestamp
    );
    event SaleActiveTimestampUpdated(
        uint256 oldSaleActiveTimestamp,
        uint256 saleActiveTimestamp
    );
    event RefundsActiveUpdated(bool oldRefundsActive, bool refundsActive);
    event BaseURIUpdated(string oldBaseURI, string baseURI);

    constructor(
        uint256 wlActiveTimestamp_,
        uint256 saleActiveTimestamp_,
        string memory baseURI_,
        address osProxyRegistryAddress,
        address[] memory operators,
        address[] memory wlSigners
    ) EIP712("ToonPals", "1") ERC721A("ToonPals", "TP") {
        wlActiveTimestamp = wlActiveTimestamp_;
        saleActiveTimestamp = saleActiveTimestamp_;
        baseURI = baseURI_;
        _osProxyRegistry = OSProxyRegistry(osProxyRegistryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        for (uint256 index = 0; index < operators.length; ++index) {
            _grantRole(OPERATOR_ROLE, operators[index]);
        }
        for (uint256 index = 0; index < wlSigners.length; ++index) {
            _grantRole(WL_SIGNER_ROLE, wlSigners[index]);
        }

        _safeMint(_msgSender(), reservedPals);
    }

    /**
     * @dev Promotional Mint function, enabled manually via {ToonPals-setPromoThreshold}.
     * Recipient must be an EOA.
     */
    function mintPromo(uint256 quantity) external {
        if (promoActive() != true) revert PromoNotActive();
        if (_msgSender() != tx.origin) revert RecipientIsNotEOA();
        if (quantity > maxPromoMintQuantity) revert MaxMintQuantityExceeded();
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyExceeded();

        transactionRecords[_msgSender()].promoRedemptions += quantity;
        _transactingAddresses.add(_msgSender());
        _safeMint(_msgSender(), quantity);
    }

    /**
     * @dev Whitelist Mint function, payable. With a valid signature from an account
     * with an operator role, accounts may mint up to maxWLMintQuantity tokens.
     */
    function mintWL(bytes calldata sig, uint256 quantity) external payable {
        if (wlActive() != true) revert SaleNotActive(block.timestamp);
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyExceeded();

        uint256 cost = quantity * mintValue;
        if (cost != msg.value) revert IncorrectEtherValueSent(cost);

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _msgSender()))
        );
        address signer = ECDSA.recover(digest, sig);
        if (hasRole(WL_SIGNER_ROLE, signer) != true) revert InvalidSignature();

        uint256 wlPurchased = transactionRecords[_msgSender()].wlPurchases;
        uint256 allowance = maxWLMintQuantity - wlPurchased;
        if (quantity > allowance) revert ExceedsAvailableAllowance(allowance);

        transactionRecords[_msgSender()].wlPurchases += quantity;
        _transactingAddresses.add(_msgSender());
        _safeMint(_msgSender(), quantity);
    }

    /**
     * @dev Public Mint function, payable. Accounts may mint up to maxMintQuantity
     * tokens per transaction.
     */
    function mint(uint256 quantity) external payable {
        if (saleActive() != true) revert SaleNotActive(block.timestamp);
        if (quantity > maxMintQuantity) revert MaxMintQuantityExceeded();
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyExceeded();

        uint256 cost = quantity * mintValue;
        if (cost != msg.value) revert IncorrectEtherValueSent(cost);

        transactionRecords[_msgSender()].salePurchases += quantity;
        _transactingAddresses.add(_msgSender());
        _safeMint(_msgSender(), quantity);
    }

    /**
     * @dev Refund function, enabled manually via {ToonPals-setRefundsActive}.
     * Refunds are made according to the number of paid transactions and must
     * burn the respective number of tokens in return.
     */
    function refund(uint256[] calldata tokenIds) external nonReentrant {
        if (refundsActive != true) revert RefundsNotActive();

        TransactionRecord storage record = transactionRecords[_msgSender()];

        uint256 quantityPurchased = record.wlPurchases + record.salePurchases;
        uint256 quantityRefunded = record.refundQuantity;
        uint256 quantityAvailableForRefund = quantityPurchased -
            quantityRefunded;
        if (quantityAvailableForRefund == 0) revert ZeroRefundAvailable();
        if (tokenIds.length != quantityAvailableForRefund)
            revert InvalidValue();

        uint256 refundAmount = quantityAvailableForRefund * mintValue;
        if (address(this).balance < refundAmount)
            revert ContractFundsInsufficient();

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            if (ownerOf(tokenId) != _msgSender()) revert NotTokenOwner();

            _burn(tokenId);
        }

        record.refundQuantity += quantityAvailableForRefund;
        payable(_msgSender()).sendValue(refundAmount);
    }

    /**
     * @dev ToonPals Pass Mint function. Accounts who held a ToonPals Pass
     * on 05/05/2022 11:59:00PM EST are to be minted a token. The number
     * of ToonPals minted is equal to the number of ToonPals Passes held at
     * the time of the snapshot.
     */
    function mintTpp(
        address[] calldata addresses,
        uint256[] calldata quantities
    ) external onlyRole(OPERATOR_ROLE) {
        if (tppMinted == true) revert TPPPreviouslyMinted();
        if (addresses.length != quantities.length) revert InvalidValue();

        for (uint256 index = 0; index < addresses.length; ++index) {
            _safeMint(addresses[index], quantities[index]);
        }

        tppMinted = true;
    }

    /**
     * @dev Special Mint function. For miscellaneous purposes, e.g. raffles.
     */
    function mintSpecial(address[] calldata addresses)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (_totalMinted() + addresses.length > maxSupply)
            revert MaxSupplyExceeded();

        for (uint256 index = 0; index < addresses.length; ++index) {
            _safeMint(addresses[index], 1);
        }
    }

    /**
     * @dev Reserve Mint function.
     */
    function mintReserve(address to, uint256 quantity)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (_totalMinted() + quantity > maxSupply) revert MaxSupplyExceeded();

        _safeMint(to, quantity);
    }

    function setMaxPromoMintQuantity(uint256 maxPromoMintQuantity_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (maxPromoMintQuantity == maxPromoMintQuantity_)
            revert ValueUnchanged();

        uint256 oldMaxPromoMintQuantity = maxPromoMintQuantity;
        maxPromoMintQuantity = maxPromoMintQuantity_;

        emit MaxPromoMintQuantityUpdated(
            oldMaxPromoMintQuantity,
            maxPromoMintQuantity
        );
    }

    function setMaxWLMintQuantity(uint256 maxWLMintQuantity_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (maxWLMintQuantity == maxWLMintQuantity_) revert ValueUnchanged();

        uint256 oldMaxWLMintQuantity = maxWLMintQuantity;
        maxWLMintQuantity = maxWLMintQuantity_;

        emit MaxWLMintQuantityUpdated(oldMaxWLMintQuantity, maxWLMintQuantity);
    }

    function setMaxMintQuantity(uint256 maxMintQuantity_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (maxMintQuantity == maxMintQuantity_) revert ValueUnchanged();

        uint256 oldMaxMintQuantity = maxMintQuantity;
        maxMintQuantity = maxMintQuantity_;

        emit MaxMintQuantityUpdated(oldMaxMintQuantity, maxMintQuantity);
    }

    function setPromoThreshold(uint256 promoThreshold_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (promoThreshold == promoThreshold_) revert ValueUnchanged();

        uint256 oldPromoThreshold = promoThreshold;
        promoThreshold = promoThreshold_;

        emit PromoThresholdUpdated(oldPromoThreshold, promoThreshold);
    }

    function setWLActiveTimestamp(uint256 wlActiveTimestamp_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (wlActiveTimestamp == wlActiveTimestamp_) revert ValueUnchanged();

        uint256 oldWLActiveTimestamp = wlActiveTimestamp;
        wlActiveTimestamp = wlActiveTimestamp_;

        emit WLActiveTimestampUpdated(oldWLActiveTimestamp, wlActiveTimestamp);
    }

    function setSaleActiveTimestamp(uint256 saleActiveTimestamp_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (saleActiveTimestamp == saleActiveTimestamp_)
            revert ValueUnchanged();

        uint256 oldSaleActiveTimestamp = saleActiveTimestamp;
        saleActiveTimestamp = saleActiveTimestamp_;

        emit SaleActiveTimestampUpdated(
            oldSaleActiveTimestamp,
            saleActiveTimestamp
        );
    }

    function setRefundsActive(bool refundsActive_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (refundsActive == refundsActive_) revert ValueUnchanged();

        bool oldRefundsActive = refundsActive;
        refundsActive = refundsActive_;

        emit RefundsActiveUpdated(oldRefundsActive, refundsActive);
    }

    function setBaseURI(string memory baseURI_)
        external
        onlyRole(OPERATOR_ROLE)
    {
        if (
            keccak256(abi.encodePacked(baseURI_)) ==
            keccak256(abi.encodePacked(_baseURI()))
        ) revert ValueUnchanged();

        string memory oldBaseURI = _baseURI();
        baseURI = baseURI_;

        emit BaseURIUpdated(oldBaseURI, baseURI_);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(_msgSender()).sendValue(address(this).balance);
    }

    /**
     * @dev Number of tokens minted.
     */
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Number of tokens burned.
     */
    function totalBurned() external view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev The set of addresses stored within transactionRecords.
     */
    function transactingAddresses() external view returns (address[] memory) {
        return _transactingAddresses.values();
    }

    function promoActive() public view returns (bool) {
        return _totalMinted() < promoThreshold;
    }

    function wlActive() public view returns (bool) {
        return block.timestamp >= wlActiveTimestamp;
    }

    function saleActive() public view returns (bool) {
        return block.timestamp >= saleActiveTimestamp;
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        if (super.isApprovedForAll(owner_, operator)) {
            return true;
        }

        if (
            address(_osProxyRegistry) != address(0) &&
            address(_osProxyRegistry.proxies(owner_)) == operator
        ) {
            return true;
        }

        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControl, ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}
