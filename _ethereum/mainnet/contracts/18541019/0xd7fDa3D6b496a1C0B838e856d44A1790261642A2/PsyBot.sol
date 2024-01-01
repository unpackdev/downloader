// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract PsyBot is
    Initializable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable
{
    using StringsUpgradeable for uint256;

    /* ===== CONSTANTS ===== */

    // SALE_HELPER_ROLE should be granted to PsyBotSaleHelper
    bytes32 public constant SALE_HELPER_ROLE = keccak256("SALE_HELPER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant SUPPLY_SETTER_ROLE = keccak256("SUPPLY_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /* ===== GENERAL ===== */

    bool public isRevealed;
    // same for all tokens
    string public unrevealedURI;
    // token ID is appended to this URI
    string public revealedURI;

    uint256 public totalSupply;
    uint256 public supplyCap;

    /* ===== EVENTS ===== */

    event IsRevealedSet(bool revealed);
    event UnrevealedURISet(string newUnrevealedURI);
    event RevealedURISet(string newRevealedURI);
    event SupplyCapSet(uint256 newSupplyCap);

    /* ===== CONSTRUCTOR ===== */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _supplyCap) public initializer {
        __ERC721_init("PsyBot", "$PSYBOT");
        __ERC721Pausable_init();
        __AccessControlEnumerable_init();
        __UUPSUpgradeable_init();

        supplyCap = _supplyCap;

        _pause();

        address msgSender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, msgSender);
        _grantRole(URI_SETTER_ROLE, msgSender);
        _grantRole(PAUSER_ROLE, msgSender);
        _grantRole(UPGRADER_ROLE, msgSender);
    }

    /* ===== VIEWABLE ===== */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        if (isRevealed) {
            return getRevealedURI(tokenId);
        } else {
            return unrevealedURI;
        }
    }

    function getRevealedURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(revealedURI, tokenId.toString()));
    }

    /* ===== FUNCTIONALITY ===== */

    function mint(
        address to
    ) public whenNotPaused onlyRole(SALE_HELPER_ROLE) {
        // no burning, use total supply to assign ids
        _safeMint(to, totalSupply);
    }

    /* ===== MUTATIVE ===== */

    function setIsRevealed(bool _isRevealed)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        isRevealed = _isRevealed;

        emit IsRevealedSet(_isRevealed);
    }

    function setUnrevealedURI(string calldata newUnrevealedURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        unrevealedURI = newUnrevealedURI;

        emit UnrevealedURISet(newUnrevealedURI);
    }

    function setRevealedURI(string calldata newRevealedURI)
        external
        onlyRole(URI_SETTER_ROLE)
    {
        revealedURI = newRevealedURI;

        emit RevealedURISet(newRevealedURI);
    }

    function setSupplyCap(uint256 newSupplyCap)
        external
        onlyRole(SUPPLY_SETTER_ROLE)
    {
        supplyCap = newSupplyCap;

        emit SupplyCapSet(newSupplyCap);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /* ===== INTERNAL ===== */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        override(
            ERC721Upgradeable,
            ERC721PausableUpgradeable
        )
    {

        if (from == address(0)) {
            totalSupply++;
            require(
                totalSupply <= supplyCap,
                "PsyBot: max supply reached"
            );
        } else if (from != address(0) && totalSupply < supplyCap) {
            revert("PsyBot: Need to mint out first");
        }

        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
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
        override(
            ERC721Upgradeable,
            AccessControlEnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
