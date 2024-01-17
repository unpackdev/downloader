// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

import "./CurrencyTransferLib.sol";

abstract contract BucketEditionUpgradable is Initializable, AccessControlEnumerableUpgradeable {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @dev Only EDITIONS_ADMIN_ROLE holders can set bucket editions and prices
    bytes32 public constant EDITIONS_ADMIN_ROLE = keccak256("EDITIONS_ADMIN_ROLE");
    /// @dev Only WITHDRAWER_ROLE holders can withdraw ethers and erc20 tokens
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    /// @dev Minimal bucket edition id
    uint256 public constant MIN_EDITION_ID = 1;
    /// @dev Maximal bucket edition id
    uint256 public constant MAX_EDITION_ID = 100;
    /// @dev First token id of an edition is: EDITION_TOKEN_ID_FACTOR * editionId
    uint256 public constant EDITION_TOKEN_ID_FACTOR = 1_000_000;
    /// @dev Upper limit of an bucket edition's maximal mintable supply
    uint256 public constant EDITION_MAX_MINTABLE_SUPPLY = 1_000_000;

    /// @dev All bucket editions that have ever set
    EnumerableSetUpgradeable.UintSet internal _allEditions;
    /// @dev Maximal mintable supply of all editions
    EnumerableMapUpgradeable.UintToUintMap internal _allEditionsMaxSupply;
    /// @dev Capacity limit of all editions
    EnumerableMapUpgradeable.UintToUintMap internal _allEditionsCapacity;
    /// @dev Currently minted supply of all editions
    EnumerableMapUpgradeable.UintToUintMap internal _allEditionsCurrentSupplyMinted;
    /// @dev Version numbers of all editions
    EnumerableMapUpgradeable.UintToUintMap internal _allEditionsVersion;
    /// @dev Latest active edition version number
    CountersUpgradeable.Counter internal _currentEditionsVersion;

    /// @dev Mapping from edition id to (Currency Address => Price) mapping
    mapping(uint256 => EnumerableMapUpgradeable.AddressToUintMap) internal _allEditionPrices;

    /**
     * @notice                      Paramer structs for EDITIONS_ADMIN_ROLE holders to update bucket editions
     * 
     * @param editionId             Edition id, should be between [MIN_EDITION_ID, MAX_EDITION_ID]
     * 
     * @param capacityInGigabytes   Capacity of this edition buckets, in gigabytes (GB). 0 for unlimited
     * 
     * @param maxMintableSupply     Maximal mintable supply of the bucket edition, should be no larger than EDITION_MAX_MINTABLE_SUPPLY
     */
    struct BucketEditionParams {
        uint256 editionId;
        uint256 capacityInGigabytes;
        uint256 maxMintableSupply;
    }

    /**
     * @notice                      Detailed information about a bucket edition
     * 
     * @param editionId             Edition id
     * 
     * @param active                Whether this edition is active. Only active edition tokens could be minted
     * 
     * @param capacityInGigabytes   Capacity of this edition buckets, in gigabytes (GB). 0 for unlimited
     * 
     * @param maxMintableSupply     Maximal mintable supply of this edition
     * 
     * @param currentSupplyMinted   At any given point, the number of tokens that have been minted of this edition
     */
    struct BucketEdition {
        uint256 editionId;
        bool active;
        uint256 capacityInGigabytes;
        uint256 maxMintableSupply;
        uint256 currentSupplyMinted;
    }

    /**
     * @notice                      A price information of a bucket edition
     * 
     * @param currency              The currency in which the `price` must be paid
     * 
     * @param price                 The price required to pay to mint a token of the associated bucket edition
     */
    struct EditionPrice {
        address currency;
        uint256 price;
    }

    /// @notice Emitted when a bucket edition is updated
    event EditionUpdated(
        uint256 indexed editionId,
        uint256 capacityInGigabytes,
        uint256 maxMintableSupply
    );

    /// @notice Emitted when a bucket edition's price is updated
    event EditionPriceUpdated(
        uint256 indexed editionId,
        address indexed currency,
        uint256 price
    );

    /// @notice Emitted when a bucket token is minted
    event BucketMinted(
        address indexed to,
        uint256 indexed editionId,
        uint256 indexed tokenId,
        uint256 capacityInGigabytes,
        address currency,
        uint256 price
    );

    // @notice Indicate to OpenSea that an NFT's metadata is no longer changeable by anyone (in other words, it is "frozen")
    event PermanentURI(
        string _value,
        uint256 indexed _id
    );

    /// @notice Emitted when a currency is withdrawn
    event Withdraw(
        address indexed to,
        address indexed currency,
        uint256 amount
    );

    function __BucketEditionUpgradable_init() internal onlyInitializing {
        
    }

    function __BucketEditionUpgradable_init_unchained() internal onlyInitializing {
    }

    function _isValid(BucketEditionParams memory edition) internal view virtual returns (bool) {
        return (edition.editionId >= MIN_EDITION_ID)
            && (edition.editionId <= MAX_EDITION_ID)
            && (edition.maxMintableSupply <= EDITION_MAX_MINTABLE_SUPPLY); 
    }

    function _requireActiveEdition(uint256 editionId) internal view {
        require(
            _allEditions.contains(editionId) && _allEditionsVersion.get(editionId) == _currentEditionsVersion.current(), 
            'Invalid or inactive edition'
        );
    }

    function _nextEditionTokenId(uint256 editionId) internal view returns (uint256) {
        uint256 supplyMinted = _allEditionsCurrentSupplyMinted.contains(editionId) ? _allEditionsCurrentSupplyMinted.get(editionId) : 0;
        return SafeMathUpgradeable.add(SafeMathUpgradeable.mul(editionId, EDITION_TOKEN_ID_FACTOR), supplyMinted);
    }

    function _editionTokenMinted(uint256 editionId) internal {
        uint256 supplyMinted = _allEditionsCurrentSupplyMinted.contains(editionId) ? _allEditionsCurrentSupplyMinted.get(editionId) : 0;
        _allEditionsCurrentSupplyMinted.set(editionId, supplyMinted + 1);
    }

    /**
     * @dev Update bucket editions
     */
    function setBucketEditions(BucketEditionParams[] calldata editions)
        external
        virtual
        onlyRole(EDITIONS_ADMIN_ROLE) {
        _currentEditionsVersion.increment();
        uint256 version = _currentEditionsVersion.current();

        for (uint256 i = 0; i < editions.length; i++) {
            require(_isValid(editions[i]), 'Invalid bucket edition');

            BucketEditionParams memory edition = editions[i];
            _allEditions.add(edition.editionId);
            _allEditionsCapacity.set(edition.editionId, edition.capacityInGigabytes);
            _allEditionsMaxSupply.set(edition.editionId, edition.maxMintableSupply);
            _allEditionsVersion.set(edition.editionId, version);
            // console.log('setBucketEditions, %s, edition id: %s, maxMintableSupply: %s', i, edition.editionId, edition.maxMintableSupply);

            emit EditionUpdated(edition.editionId, edition.capacityInGigabytes, edition.maxMintableSupply);
        }
    }

    function getBucketEditions(bool activeOnly)
        public
        virtual
        view
        returns (BucketEdition[] memory)
    {
        uint256 count = 0;
        uint256 currentVersion = _currentEditionsVersion.current();
        // console.log('getBucketEditions, currentVersion: %s', currentVersion);

        for (uint256 i = 0; i < _allEditions.length(); i++) {
            uint256 editionId = _allEditions.at(i);

            bool active = _allEditionsVersion.get(editionId) == currentVersion;
            uint256 currentSupplyMinted = _allEditionsCurrentSupplyMinted.contains(editionId) ? _allEditionsCurrentSupplyMinted.get(editionId) : 0;
            bool shouldInclude = active || (!activeOnly && currentSupplyMinted > 0);
            if (shouldInclude) {
                count++;
            }
        }
        // console.log('getBucketEditions, count: %s', count);

        BucketEdition[] memory editions = new BucketEdition[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _allEditions.length(); i++) {
            uint256 editionId = _allEditions.at(i);

            bool active = _allEditionsVersion.get(editionId) == currentVersion;
            uint256 currentSupplyMinted = _allEditionsCurrentSupplyMinted.contains(editionId) ? _allEditionsCurrentSupplyMinted.get(editionId) : 0;
            bool shouldInclude = active || (!activeOnly && currentSupplyMinted > 0);
            if (shouldInclude) {
                editions[index].editionId = editionId;
                editions[index].active = active;
                editions[index].capacityInGigabytes = _allEditionsCapacity.get(editionId);
                editions[index].maxMintableSupply = _allEditionsMaxSupply.get(editionId);
                editions[index].currentSupplyMinted = currentSupplyMinted;
                index++;
            }
        }

        return editions;
    }

    /**
     * @dev Update a bucket edition prices
     */
    function setBucketEditionPrices(uint256 editionId, EditionPrice[] calldata prices)
        external
        virtual
        onlyRole(EDITIONS_ADMIN_ROLE) 
    {
        _requireActiveEdition(editionId);

        EnumerableMapUpgradeable.AddressToUintMap storage editionPrices = _allEditionPrices[editionId];
        for (uint256 i = 0; i < editionPrices.length(); ) {
            (address key, ) = editionPrices.at(i);
            editionPrices.remove(key);
        }

        for (uint256 i = 0; i < prices.length; i++) {
            editionPrices.set(prices[i].currency, prices[i].price);

            emit EditionPriceUpdated(editionId, prices[i].currency, prices[i].price);
        }
    }

    function getBucketEditionPrices(uint256 editionId)
        public
        virtual
        view
        returns (EditionPrice[] memory)
    {
        _requireActiveEdition(editionId);

        EnumerableMapUpgradeable.AddressToUintMap storage editionPrices = _allEditionPrices[editionId];
        EditionPrice[] memory prices = new EditionPrice[](editionPrices.length());
        for (uint256 i = 0; i < editionPrices.length(); i++) {
            (address key, uint256 price) = editionPrices.at(i);
            prices[i].currency = key;
            prices[i].price = price;
        }
        return prices;
    }

    /**
     * @dev Withdraw native token or erc20 tokens from the contract
     */
    function withdraw(address to, address currency)
        external
        virtual
        onlyRole(WITHDRAWER_ROLE) 
    {
        uint256 amount = 0;
        if (currency == CurrencyTransferLib.NATIVE_TOKEN) {
            amount = address(this).balance;
        }
        else {
            amount = IERC20Upgradeable(currency).balanceOf(address(this));
        }

        if (amount == 0) {
            return;
        }

        CurrencyTransferLib.transferCurrency(currency, address(this), to, amount);
        emit Withdraw(to, currency, amount);
    }


    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}