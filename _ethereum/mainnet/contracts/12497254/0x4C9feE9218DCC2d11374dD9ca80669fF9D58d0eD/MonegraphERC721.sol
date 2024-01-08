// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "./ERC721Upgradeable.sol";

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./ERC721PausableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

import "./AccessControlUpgradeable.sol";

import "./ContextUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract MonegraphERC721 is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721PausableUpgradeable,
    ERC721URIStorageUpgradeable,
    UUPSUpgradeable
{
    event NFTAttributes(uint256 tokenId, Attributes attributes, string uri);

    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    CountersUpgradeable.Counter private _tokenIdTracker;

    address public initializedBy;

    struct Attributes {
        string language;
        string artist;
        string year;
        string royalty;
        string title;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address admin
    ) public virtual initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC721URIStorage_init_unchained();
        __UUPSUpgradeable_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(MINTER_ROLE, admin);
        _setupRole(PAUSER_ROLE, admin);

        initializedBy = admin;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "";
    }

    function isNotEmptyString(string memory _string)
        internal
        pure
        returns (bool)
    {
        return bytes(_string).length > 0;
    }

    function mint(address to, string memory uri) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "MonegraphERC721: must have minter role to mint"
        );

        require(
            isNotEmptyString(uri),
            "MonegraphERC721: TokenUri can not be empty"
        );

        uint256 tokenId = _tokenIdTracker.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);

        _tokenIdTracker.increment();
    }

    function mint(
        address to,
        string memory uri,
        Attributes memory attributes
    ) public virtual {
        uint256 tokenId = _tokenIdTracker.current();

        mint(to, uri);

        emit NFTAttributes(tokenId, attributes, tokenURI(tokenId));
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        return super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC721: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "MonegraphERC721: must have pauser role to unpause"
        );
        _unpause();
    }

    function batchGrantMinters(address[] memory addresses)
        public
        virtual
        onlyRole(getRoleAdmin(MINTER_ROLE))
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            grantRole(MINTER_ROLE, addresses[i]);
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721PausableUpgradeable
        )
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address)
        internal
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {}
}
