// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";

import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./CurrencyTransferLib.sol";
import "./BucketEditionUpgradable.sol";

contract W3Bucket is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    BucketEditionUpgradable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string memory name, string memory symbol) initializer public {
        __ERC721_init(name, symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC721Burnable_init();
        __UUPSUpgradeable_init();
        __BucketEditionUpgradable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(EDITIONS_ADMIN_ROLE, msg.sender);
        _grantRole(WITHDRAWER_ROLE, msg.sender);
    }

    receive() external payable virtual {}

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    function mint(
        address to,
        uint256 editionId,
        address currency,
        string calldata uri
    ) external virtual payable nonReentrant 
    {
        require(_msgSender() == tx.origin, 'BOT');

        _requireActiveEdition(editionId);
        // console.log('mint, edition active: %s', editionId);

        uint256 maxSupply = _allEditionsMaxSupply.get(editionId);
        uint256 supplyMinted = _allEditionsCurrentSupplyMinted.contains(editionId) ? _allEditionsCurrentSupplyMinted.get(editionId) : 0;
        require(supplyMinted < maxSupply, 'Exceed max mintable supply');
        // console.log('mint, edition max supply: %s, currently minted: %s', maxSupply, supplyMinted);

        EnumerableMapUpgradeable.AddressToUintMap storage editionPrices = _allEditionPrices[editionId];
        require(editionPrices.contains(currency), 'Invalid currency');

        uint256 price = editionPrices.get(currency);
        if (currency == CurrencyTransferLib.NATIVE_TOKEN) {
            // console.log('mint, native currency, msg.value: %s', msg.value);
            require(msg.value == price, "Must send required price");
        }
        else {
            CurrencyTransferLib.transferCurrency(currency, _msgSender(), address(this), price);
        }

        uint256 nextTokenId = _nextEditionTokenId(editionId);
        _safeMint(to, nextTokenId);
        _setTokenURI(nextTokenId, uri);
        _editionTokenMinted(editionId);

        uint capacityInGigabytes = _allEditionsCapacity.get(editionId);
        emit BucketMinted(to, editionId, nextTokenId, capacityInGigabytes, currency, price);
        emit PermanentURI(uri, nextTokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}