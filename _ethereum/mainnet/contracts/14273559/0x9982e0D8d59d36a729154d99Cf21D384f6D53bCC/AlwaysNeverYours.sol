// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;


/////////////////////////////////////////////////////////////////////////////////
//                                                                             //
//                                                                             //
//      ██████╗░███████╗███████╗████████╗░██████╗██████╗░░█████╗░░█████╗░      //
//      ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██╔══██╗      //
//      ██████╦╝█████╗░░█████╗░░░░░██║░░░╚█████╗░██║░░██║███████║██║░░██║      //
//      ██╔══██╗██╔══╝░░██╔══╝░░░░░██║░░░░╚═══██╗██║░░██║██╔══██║██║░░██║      //
//      ██████╦╝███████╗███████╗░░░██║░░░██████╔╝██████╔╝██║░░██║╚█████╔╝      //
//      ╚═════╝░╚══════╝╚══════╝░░░╚═╝░░░╚═════╝░╚═════╝░╚═╝░░╚═╝░╚════╝░      //
//                                                                             //
//                                                                             //
/////////////////////////////////////////////////////////////////////////////////


import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

/**
 * @title ERC721 token for A̶l̶w̶a̶y̶s̶ Never Yours
 * @author swaHili
 * @notice Assets are controlled through the property rights enforced by Harberger taxation
 */
contract AlwaysNeverYours is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Base time interval in seconds used to calculate foreclosure date (24 hours)
    uint256 public constant BASE_INTERVAL = 86400 seconds;

    // Base tax denominator used to caculated 0.1% daily tax rate (36.5% annual)
    uint256 private constant BASE_TAX_DENOMINATOR = 1000;

    // Percentage of sales price used to calculate royalty fee
    uint256 public constant ROYALTY_PERCENTAGE = 10;

    // Percentage of sales price used to calculate minimum tax fee
    uint256 public constant TAX_PERCENTAGE = 10;

    // Zora Auction House
    address public auctionHouse = 0xE468cE99444174Bd3bBBEd09209577d25D1ad673;

    // Owner of contract
    address public admin;

    // Mapping tokenId to Asset struct
    mapping(uint256 => Asset) public assets;

    // Mapping tokenId to base tax value which is used to calculate foreclosure date
    mapping(uint256 => uint256) public baseTaxValues;

    // Mapping tokenId to IPFS CID hash of metadata
    mapping(uint256 => string) public ipfsMetadataHashes;

    // Mapping tokenId to address of tax collector account
    mapping(uint256 => address) public taxCollectors;

    /**
     * @notice Object that represents the current state of each asset
     * `creator` Address of the artist who created the asset
     * `priceAmount` Price amount of the asset
     * `taxAmount` Minimum tax amount of the asset
     * `totalDepositAmount` Total amount deposited by the current owner of the asset
     * `previousListingPrice` Price of asset when it was previously listed by the current owner
     * `foreclosureTimestamp` Timestamp of the foreclosure for which taxes must be paid by the current owner
     */
    struct Asset {
        address creator;
        uint256 priceAmount;
        uint256 taxAmount;
        uint256 totalDepositAmount;
        uint256 previousListingPrice;
        uint256 foreclosureTimestamp;
    }

    /**
     * @notice List of possible events emitted after every transaction.
     */
    event Mint       (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to);
    event List       (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, uint256 value);
    event Deposit    (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to, uint256 value);
    event Sale       (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to, uint256 value);
    event Refund     (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to, uint256 value);
    event Collect    (uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to, uint256 value);
    event Foreclosure(uint256 indexed timestamp, uint256 indexed tokenId, address indexed from, address to);

    /**
     * @notice Initializes contract and sets `admin` to specified owner of contract.
     * @param _admin Address of the contract admin
     */
    constructor(address _admin) ERC721("Always Never Yours", "ANY") {
        admin = _admin;
    }

    /**
     * @notice Modifier that checks if `admin` is equal to `msgSender`.
     */
    modifier onlyAdmin() {
        require(admin == _msgSender(), "OnlyAdmin: Invalid authorization");
        _;
    }

    /**
     * @notice Modifier that checks if `creator` of asset is equal to `msgSender`.
     * @param _tokenId ID of the token
     */
    modifier onlyCreator(uint256 _tokenId) {
        require(assets[_tokenId].creator == _msgSender(), "OnlyCreator: Invalid authorization");
        _;
    }

    /**
     * @notice Modifier that checks if `admin` or `creator` of asset is equal to `msgSender`.
     * @param _tokenId ID of the token
     */
    modifier onlyAdminOrCreator(uint256 _tokenId) {
        require(
            admin == _msgSender() || assets[_tokenId].creator == _msgSender(),
            "OnlyAdminOrCreator: Invalid authorization"
        );
        _;
    }

    /**
     * @notice Modifier that checks if `owner` of asset is equal to `msgSender`.
     * @param _tokenId ID of the token
     */
    modifier onlyOwner(uint256 _tokenId) {
        require(ownerOf(_tokenId) == _msgSender(), "OnlyOwner: Invalid authorization");
        _;
    }

    /**
     * @notice Modifier that checks if `tokenId` exists.
     * @param _tokenId ID of the token
     */
    modifier validToken(uint256 _tokenId) {
        require(_exists(_tokenId), "Invalid token");
        _;
    }

    /**
     * @notice Mints `tokenId`, transfers it to `creator`, sets `tokenURI` and initializes asset state.
     * @param _arweaveId Arweave ID used for tokenURI
     * @param _ipfsMetadataHash IPFS CID hash of metadata
     * @param _creator Address of artist who created the asset
     * @param _taxCollector Address of tax collector account
     * @return newTokenId of the newly created token
     *
     * Requirements:
     *
     * - `admin` must be equal to `msgSender`.
     *
     * Emits a {Mint & Transfer} event.
     */
    function mintAsset(
        string memory _arweaveId,
        string memory _ipfsMetadataHash,
        address _creator,
        address _taxCollector
    ) external onlyAdmin returns (uint256 newTokenId) {
        _tokenIds.increment();
        newTokenId = _tokenIds.current();

        emit Mint(block.timestamp, newTokenId, address(0), _creator);
        _safeMint(_creator, newTokenId, "");
        _setTokenURI(newTokenId, _arweaveId);

        ipfsMetadataHashes[newTokenId] = _ipfsMetadataHash;
        taxCollectors[newTokenId] = _taxCollector;

        Asset storage asset = assets[newTokenId];
        asset.creator = _creator;
        asset.foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
    }

    /**
     * @notice Lists asset for sale in wei and sets corresponding tax price.
     * @param _tokenId ID of the token
     * @param _priceAmount Price amount of the asset
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `owner` of asset must be equal to `msgSender`.
     * - 'priceAmount' of asset must be greater than 0.
     * - 'foreclosure' of asset must not be in process OR `msgSender` must be equal to creator OR `msgSender` must be equal to `admin`.
     *
     * Emits a {List} event.
     */
    function listAssetInWei(uint256 _tokenId, uint256 _priceAmount) external validToken(_tokenId) onlyOwner(_tokenId) {
        address sender = _msgSender();
        Asset storage asset = assets[_tokenId];
        require(_priceAmount > 0, "ListAsset: Must set price greater than 0");
        require(asset.priceAmount != _priceAmount, "ListAsset: Price must be different than current value");
        require(
            !foreclosure(_tokenId) || assets[_tokenId].creator == sender || admin == sender,
            "ListAsset: Foreclosure has already begun"
        );

        asset.priceAmount = _priceAmount;
        asset.taxAmount = _priceAmount / TAX_PERCENTAGE;
        uint256 newBaseTaxValue = _priceAmount / BASE_TAX_DENOMINATOR;
        uint256 currentBaseTaxValue = baseTaxValues[_tokenId];

        if (asset.previousListingPrice != _priceAmount && asset.totalDepositAmount > 0) {
            uint256 timeRemaining = asset.foreclosureTimestamp - block.timestamp - BASE_INTERVAL;
            uint256 depositRemaining = (timeRemaining * currentBaseTaxValue) / BASE_INTERVAL;

            asset.foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
            asset.foreclosureTimestamp += (depositRemaining * BASE_INTERVAL) / newBaseTaxValue;
            asset.previousListingPrice = _priceAmount;
        }

        baseTaxValues[_tokenId] = newBaseTaxValue;
        emit List(block.timestamp, _tokenId, sender, _priceAmount);
    }

    /**
     * @notice Deposits taxes into contract.
     * @param _tokenId ID of the token
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `owner` of asset must be equal to `msgSender`.
     * - `priceAmount` of asset must be greater than 0.
     * - `msg.value` must be greater than or equal to `taxAmount`.
     * - 'foreclosure' of asset must not be in process.
     *
     * Emits a {Deposit} event.
     */
    function depositTax(uint256 _tokenId) external payable validToken(_tokenId) onlyOwner(_tokenId) nonReentrant {
        Asset storage asset = assets[_tokenId];
        require(asset.priceAmount > 0, "DepositTax: Must first set sales price");
        require(msg.value >= asset.taxAmount, "DepositTax: Amount must not be less than minimum tax fee");
        require(!foreclosure(_tokenId), "DepositTax: Foreclosure has already begun");

        asset.totalDepositAmount += msg.value;
        asset.foreclosureTimestamp += (msg.value * BASE_INTERVAL) / baseTaxValues[_tokenId];

        emit Deposit(block.timestamp, _tokenId, _msgSender(), address(this), msg.value);
    }

    /**
     * @notice Purchase of asset triggers tax refund, payment transfers and asset transfer.
     * @param _tokenId ID of the token
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `owner` of asset must not be equal to `msgSender`.
     * - `priceAmount` of asset must be greater than 0.
     * - `priceAmount` of asset must be equal to `msg.value`.
     *
     * Emits a {Sale} event.
     */
    function buyAsset(uint256 _tokenId) external payable validToken(_tokenId) nonReentrant {
        address sender = _msgSender();
        Asset storage asset = assets[_tokenId];
        require(ownerOf(_tokenId) != sender, "BuyAsset: Already owner");
        require(asset.priceAmount > 0, "BuyAsset: Asset not up for sale");
        require(asset.priceAmount == msg.value, "BuyAsset: Invalid payment amount");

        address currentOwner = ownerOf(_tokenId);
        uint256 baseTaxValue = baseTaxValues[_tokenId];
        uint256 refundAmount = _refundTax(_tokenId, currentOwner, baseTaxValue);

        _collectTax(_tokenId, refundAmount);
        _initializeAsset(_tokenId);

        _transferPayments(_tokenId, msg.value, currentOwner);
        emit Sale(block.timestamp, _tokenId, sender, currentOwner, msg.value);

        this.safeTransferFrom(currentOwner, sender, _tokenId);
    }

    /**
     * @notice Reclaims asset and transfers it back to `creator`.
     * @param _tokenId ID of the token
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * - `creator` must be equal to `msgSender`.
     * - `foreclosure` of asset must be equal to true.
     * - `creator` must not be current owner of the asset.
     *
     * Emits a {Foreclosure} event.
     */
    function reclaimAsset(uint256 _tokenId) external validToken(_tokenId) onlyAdminOrCreator(_tokenId) {
        address sender = _msgSender();
        require(foreclosure(_tokenId), "ReclaimAsset: Time has not yet expired");
        require(ownerOf(_tokenId) != sender, "ReclaimAsset: Already owner");

        if (assets[_tokenId].totalDepositAmount > 0) {
            _collectTax(_tokenId, 0);
        }

        address currentOwner = ownerOf(_tokenId);
        emit Foreclosure(block.timestamp, _tokenId, sender, currentOwner);
        safeTransferFrom(currentOwner, sender, _tokenId);

        _initializeAsset(_tokenId);
    }

    /**
     * @notice Refunds `currentOwner` the remaining tax amount.
     * @dev Since taxes are paid in advance based on a time interval, if the asset is purchased before the foreclosure date is reached,
     * the `currentOwner` receives a portion of those taxes back. The refund calculation is simply the reverse of how the asset foreclosure date is calculated.
     * @param _tokenId ID of the token
     * @param _currentOwner Address of current owner of the asset
     * @param _baseTaxValue Base tax value currently set for the asset at the time of purchase or new tax deposit
     * @return refundAmount from excess of taxes deposited
     *
     * Emits a {Refund} event if `timeRemaining` is more than `block.timestmap` plus `BASE_INTERVAL`.
     */
    function _refundTax(uint256 _tokenId, address _currentOwner, uint256 _baseTaxValue) private returns(uint256 refundAmount) {
        Asset storage asset = assets[_tokenId];
        uint256 foreclosureTimestamp = asset.foreclosureTimestamp;

        if (foreclosureTimestamp > block.timestamp + BASE_INTERVAL) {
            uint256 remainingTimestamp = foreclosureTimestamp - block.timestamp - BASE_INTERVAL;
            refundAmount = (remainingTimestamp * _baseTaxValue) / BASE_INTERVAL;

            payable(_currentOwner).transfer(refundAmount);
            emit Refund(block.timestamp, _tokenId, address(this), _currentOwner, refundAmount);
        }
    }

    /**
     * @notice Transfers deposit amount after refund to tax collector account.
     * @param _tokenId ID of the token
     * @param _refundAmount Amount refunded to current owner
     *
     * Emits a {Collect} event.
     */
    function _collectTax(uint256 _tokenId, uint256 _refundAmount) private {
        Asset storage asset = assets[_tokenId];
        address taxCollector = taxCollectors[_tokenId];
        uint256 depositAfterRefund = asset.totalDepositAmount - _refundAmount;

        payable(taxCollector).transfer(depositAfterRefund);
        emit Collect(block.timestamp, _tokenId, address(this), address(taxCollector), depositAfterRefund);
    }

    /**
     * @notice Transfers royalties to `admin` and `creator` of asset and transfers remaining payment to `currentOwner`.
     * @param _tokenId ID of the token
     * @param _payment Value paid by the new owner
     * @param _currentOwner Address of current owner of the asset
     */
    function _transferPayments(uint256 _tokenId, uint256 _payment, address _currentOwner) private {
        uint256 royaltyAmount = _payment / ROYALTY_PERCENTAGE;
        uint256 paymentAmount = _payment - royaltyAmount;

        payable(taxCollectors[_tokenId]).transfer(royaltyAmount);
        payable(_currentOwner).transfer(paymentAmount);
    }

    /**
     * @notice Resets asset and base tax value to initial state.
     * @param _tokenId ID of the token
     */
    function _initializeAsset(uint256 _tokenId) private {
        Asset storage asset = assets[_tokenId];
        asset.priceAmount = 0;
        asset.taxAmount = 0;
        asset.totalDepositAmount = 0;
        asset.previousListingPrice = 0;
        asset.foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
        baseTaxValues[_tokenId] = 0;
    }

    /**
     * @notice Checks if current time is greater than `foreclosure` timestamp of asset.
     * @param _tokenId ID of the token
     * @return boolean value to determine status of asset foreclosure
     */
    function foreclosure(uint256 _tokenId) public view validToken(_tokenId) returns (bool) {
        return block.timestamp >= assets[_tokenId].foreclosureTimestamp;
    }

    /**
     * @notice Resets the `foreclosureTimestamp` of the asset due to one-off events, such as auctions performed through third party contracts.
     * @param _tokenId ID of the token
     */
    function resetForeclosure(uint256 _tokenId) external onlyAdmin {
        require(foreclosure(_tokenId) == true, "ResetForeclosure: Foreclosure has not yet begun");

        assets[_tokenId].foreclosureTimestamp = block.timestamp + BASE_INTERVAL;
    }

    /**
     * @notice Sets the `admin` account for controlling this contract.
     * @param _admin Address of new admin account
     */
    function setAdmin(address _admin) external onlyAdmin {
        admin = _admin;
    }

    /**
     * @notice Sets the `admin` account for controlling this contract.
     * @param _auctionHouse Address of new auction house account
     */
    function setAuctionHouse(address _auctionHouse) external onlyAdmin {
        auctionHouse = _auctionHouse;
    }

    /**
     * @notice Returns the total supply of tokens minted on this contract.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /**
     * @notice See {ERC721-baseURI}.
     */
    function _baseURI() override internal view virtual returns (string memory) {
        return "ar://";
    }

    /**
     * @notice See {ERC721-isApprovedOrOwner}.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        return (
            address(this) == spender ||
            auctionHouse == spender  ||
            (foreclosure(tokenId) && (admin == spender || assets[tokenId].creator == spender))
        );
    }
}

/*
 * External Sources:
 * https://github.com/yosriady/PatronageCollectibles
 * https://github.com/simondlr/thisartworkisalwaysonsale
 */
