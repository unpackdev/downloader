// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "./AccessControlUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";

contract DaxToken is
    Initializable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    UUPSUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    string private _defaultTokenURI;
    string private _dynamicTokenURI;
    mapping(uint256 => address) private _tokenCreators;
    CountersUpgradeable.Counter private _tokenId;

    constructor() {
        _disableInitializers();
    }

    function initialize()
    public initializer {
        __AccessControl_init();
        __ERC721_init("DaxToken", "DAXT");
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __UUPSUpgradeable_init();

        address sender = _msgSender();
        _grantRole(DEFAULT_ADMIN_ROLE, sender);
        _grantRole(CONTRACT_ADMIN_ROLE, sender);
        _grantRole(UPGRADER_ROLE, sender);

        _tokenId.increment();
        _defaultTokenURI = "ipfs://QmYmHxNxhdVwZAhE1soPgLCiLmj2a8PMyzFPAozsHFXxYM";
    }

    function creatorOf(uint256 tokenId)
    public view virtual
    returns (address) {
        address creator = _tokenCreators[tokenId];
        require(creator != address(0), "DaxToken: invalid token ID");
        
        return creator;
    }

    function edit(uint256 tokenId, string memory uri)
    public {
        address sender = _msgSender();
        require(
            ownerOf(tokenId) == sender && creatorOf(tokenId) == sender,
            "DaxToken: caller not owner and creator");

        _setTokenURI(tokenId, uri);
    }

    function exists(uint256 tokenId)
    public view
    returns (bool) {
        return _exists(tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId)
    public view
    returns (bool) {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function mint(address creator, address owner, string memory uri)
    public
    returns (uint256) {
        uint256 tokenId = _tokenId.current();
        _tokenId.increment();
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, uri);
        _tokenCreators[tokenId] = creator;

        return tokenId;
    }

    function mint()
    public
    returns (uint256) {
        address sender = _msgSender();
        return mint(sender, sender, "");
    }

    function supportsInterface(bytes4 interfaceId)
    public view override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
    public view override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = super.tokenURI(tokenId);
        if (bytes(_tokenURI).length != 0) {
            return _tokenURI;
        }
        if (bytes(_defaultTokenURI).length != 0) {
            return _defaultTokenURI;
        }
        if (bytes(_dynamicTokenURI).length != 0) {
            return string(abi.encodePacked(_dynamicTokenURI, tokenId.toString()));
        }
        return "";
    }

    function __config()
    public view
    returns (string memory defaultTokenURI, string memory dynamicTokenURI) {
        defaultTokenURI = _defaultTokenURI;
        dynamicTokenURI = _dynamicTokenURI;
    }

    function __defaultTokenURI()
    public view returns (string memory) {
        return _defaultTokenURI;
    }

    function __dynamicTokenURI()
    public view returns (string memory) {
        return _dynamicTokenURI;
    }

    function __setDefaultTokenURI(string memory uri)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _defaultTokenURI = uri;
    }

    function __setDynamicTokenURI(string memory uri)
    public onlyRole(CONTRACT_ADMIN_ROLE) {
        _dynamicTokenURI = uri;
    }

    function _authorizeUpgrade(address newImplementation)
    internal override onlyRole(UPGRADER_ROLE) {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
    internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);

        delete _tokenCreators[tokenId];
    }

    function _safeMint(address to, uint256 tokenId)
    internal override(ERC721Upgradeable) {
        super._safeMint(to, tokenId);
    }
}
