// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.14;

/*
██   ██ ██       ██████   ██████  ██    ██ 
██  ██  ██      ██    ██ ██    ██ ██    ██ 
█████   ██      ██    ██ ██    ██ ██    ██ 
██  ██  ██      ██    ██ ██    ██  ██  ██  
██   ██ ███████  ██████   ██████    ████   
*/

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";

contract ArtistV3 is
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable,
    ERC2771ContextUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _itemIds;
    CountersUpgradeable.Counter private _tokenIds;

    // The default base URI for the contract.
    string private baseURI;
    // Role in charge of pausing the contract.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // Role in charge of creating items.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // Domain of the signature used to validate a purchase.
    bytes32 public DOMAIN_SEPARATOR;

    // Mapping of Item id to Item data.
    mapping(uint256 => Item) public itemIdToItem;
    // Mapping of token id to metadata id.
    mapping(uint256 => uint256) public tokenIdToUriId;
    // Mapping of token id to Item id.
    mapping(uint256 => uint256) private tokenIdToItemId;
    // Mapping of Item id to mapping of royalty receiver to royalty amount.
    mapping(uint256 => mapping(address => uint256)) private royalties;
    // Mapping of Item id to royalty receivers.
    mapping(uint256 => address[]) private royaltiesReceivers;
    // Mapping of Item id to mapping of Klip fragment id to sold status.
    mapping(uint256 => mapping(uint256 => bool)) public klipFragmentIdToSold;

    // ==================
    // STRUCTS
    // ==================

    struct Item {
        uint32 supply;
        uint32 sold;
        uint32 startTime;
        uint256 price;
        string fullTrackHash;
    }

    // ==================
    // EVENTS
    // ==================

    event ItemCreated(
        uint256 indexed itemId,
        uint256 supply,
        uint256 startTime,
        uint256 price
    );

    event ItemPurchased(
        uint256 indexed itemId,
        uint256 tokenId,
        uint256 indexed sold,
        address indexed buyer
    );

    // ==================
    // FUNCTIONS
    // ==================

    /// @notice Initializes the contract.
    /// @param name Name of the artist.
    /// @param symbol Symbol for the artist.
    /// @param admin Default admin of the contract.
    /// @param pauser Default pauser of the contract.
    /// @param minter Default minter of the contract.
    /// @param owner Default owner of the contract.
    /// @param baseUri Default base URI for metadata.
    /// @param forwarder Default forwarder of the contract.
    function initialize(
        string calldata name,
        string calldata symbol,
        address admin,
        address pauser,
        address minter,
        address owner,
        string calldata baseUri,
        address forwarder
    ) public initializer returns (bool) {
        __ERC721_init_unchained(name, symbol);
        __Pausable_init_unchained();
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(uint256 chainId,address verifyingContract)"
                ),
                block.chainid,
                address(this)
            )
        );
        baseURI = baseUri;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
        _transferOwnership(owner);
        __ERC2771ContextUpgradeable_init_unchained(forwarder);

        return true;
    }

    /// @notice Creates a new item.
    /// @param supply Max number of tokens to be sold.
    /// @param startTime The start time of the sale for this Item.
    /// @param price The price at which each token of this Item will be sold.
    /// @param fullTrackHash Metadata hash of the Item.
    /// @param royaltyAddresses Adddresses of royalty receivers.
    /// @param royaltyAmounts Royalty amount for each roalty receiver.
    function createItem(
        uint32 supply,
        uint32 startTime,
        uint256 price,
        string calldata fullTrackHash,
        address[] calldata royaltyAddresses,
        uint256[] calldata royaltyAmounts
    ) external onlyRole(MINTER_ROLE) {
        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        itemIdToItem[itemId] = Item(supply, 0, startTime, price, fullTrackHash);

        uint256 total;
        for (uint256 i = 0; i < royaltyAddresses.length; i++) {
            require(
                royaltyAddresses[i] != address(0) && royaltyAmounts[i] > 0,
                "ArtistV3: Invalid royalties data"
            );
            royalties[itemId][royaltyAddresses[i]] = royaltyAmounts[i];
            total += royaltyAmounts[i];
        }
        royaltiesReceivers[itemId] = royaltyAddresses;
        require(
            total == 10_000,
            "ArtistV3: Royalties addition must be equal to 100%"
        );

        emit ItemCreated(itemId, supply, startTime, price);
    }

    /// @notice Mints a new token of the Item and assigns it to the buyer.
    /// @param itemId Id of the Item to purchase.
    /// @param signature Signature to authorize purchases.
    /// @param buyerAddress Address of the buyer.
    /// @param klipFragmentId Id of the Fragment to purchase. if it's not a Klip its value is 0.
    function buyItem(
        uint256 itemId,
        bytes calldata signature,
        address buyerAddress,
        uint256 klipFragmentId
    ) external payable whenNotPaused {
        require(
            itemId <= _itemIds.current(),
            "ArtistV3: Purchase for non existent itemId"
        );

        Item storage item = itemIdToItem[itemId];
        if (klipFragmentId == 0) {
            require(item.supply > item.sold, "ArtistV3: Item is sold out");
        } else {
            require(
                klipFragmentId <= item.supply,
                "ArtistV3: Purchase for non existent klipId"
            );
            require(
                !klipFragmentIdToSold[itemId][klipFragmentId],
                "ArtistV3: Item is sold out"
            );
        }
        require(
            msg.value >= item.price,
            "ArtistV3: Please submit the asking price"
        );

        require(
            item.startTime < block.timestamp,
            "ArtistV3: Item is not available yet"
        );

        require(
            hasRole(MINTER_ROLE, _verify(signature, itemId, buyerAddress)),
            "ArtistV3: Signature invalid or unauthorized"
        );

        address[] memory _royaltyReceivers = royaltiesReceivers[itemId];
        for (uint256 i = 0; i < _royaltyReceivers.length; i++) {
            uint256 royalty = royalties[itemId][_royaltyReceivers[i]];
            (bool success, ) = payable(_royaltyReceivers[i]).call{
                value: (msg.value * royalty) / 10_000
            }("");
            require(success, "ArtistV3: Transfer failed");
        }

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        tokenIdToItemId[tokenId] = itemId;
        item.sold++;

        if (klipFragmentId == 0) {
            tokenIdToUriId[tokenId] = item.sold;
        } else {
            klipFragmentIdToSold[itemId][klipFragmentId] = true;
            tokenIdToUriId[tokenId] = klipFragmentId;
        }

        _safeMint(buyerAddress, tokenId, "");
        emit ItemPurchased(itemId, tokenId, item.sold, buyerAddress);
    }

    /// @notice Mints all available tokens of an Item.
    /// @param itemId Id of the Item to mint.
    /// @param isKlip Boolean to identify the kind of Item to mint.
    function mintBatch(
        uint256 itemId,
        bool isKlip,
        address artist
    ) external onlyRole(MINTER_ROLE) {
        require(
            itemId <= _itemIds.current(),
            "ArtistV3: Purchase for non existent itemId"
        );
        Item storage item = itemIdToItem[itemId];
        require(item.supply > item.sold, "ArtistV3: Item is sold out");
        uint32 remaining = item.supply - item.sold;

        for (uint256 i = 1; i <= (isKlip ? item.supply : remaining); i++) {
            if (isKlip && klipFragmentIdToSold[itemId][i]) {
                continue;
            }
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            tokenIdToItemId[tokenId] = itemId;
            if (!isKlip) {
                tokenIdToUriId[tokenId] = item.sold + i;
            } else {
                klipFragmentIdToSold[itemId][i] = true;
                tokenIdToUriId[tokenId] = i;
            }
            _safeMint(artist, tokenId, "");
        }
        item.sold = item.supply;
    }

    /// @notice Returns the Token URI.
    /// @param tokenId Id of an existing token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ArtistV3: URI query for nonexistent token");

        return
            bytes(_baseURI()).length > 0
                ? string(
                    abi.encodePacked(
                        _baseURI(),
                        "/",
                        itemIdToItem[tokenIdToItemId[tokenId]].fullTrackHash,
                        "/",
                        tokenIdToUriId[tokenId].toString(),
                        ".json"
                    )
                )
                : "";
    }

    /// @notice Verifies the validity of the purchase.
    /// @param signature Signature required to validate the purchase.
    /// @param itemId Id of the item to purchase.
    /// @param buyerAddress Address of the buyer.
    function _verify(
        bytes calldata signature,
        uint256 itemId,
        address buyerAddress
    ) internal view returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        keccak256(
                            "SignedData(string name,uint256 itemId,address buyerAddress)"
                        ),
                        keccak256(bytes(name())),
                        itemId,
                        buyerAddress
                    )
                )
            )
        );
        return ECDSAUpgradeable.recover(digest, signature);
    }

    /// @notice Returns the base URI.
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Returns the sender of the transaction.
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address sender)
    {
        return super._msgSender();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}
