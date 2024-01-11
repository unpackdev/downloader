// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";

contract ERC721Owl is ERC721Upgradeable, ERC721BurnableUpgradeable, AccessControlUpgradeable {
    bytes32 private constant MINTER_ROLE = keccak256('MINTER_ROLE');
    bytes32 private constant URI_ROLE = keccak256('URI_ROLE');

    string public baseURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        string calldata _name,
        string calldata _symbol,
        string calldata baseURI_
    ) external initializer {
        __ERC721Owl_init(_admin, _name, _symbol, baseURI_);
    }

    function proxyInitialize(
        address _admin,
        string calldata _name,
        string calldata _symbol,
        string calldata baseURI_
    ) external onlyInitializing {
        __ERC721Owl_init(_admin, _name, _symbol, baseURI_);
    }

    function __ERC721Owl_init(
        address _admin,
        string memory _name,
        string memory _symbol,
        string memory baseURI_
    ) internal onlyInitializing {
        __ERC721Owl_init_unchained(_admin, baseURI_);
        __ERC721_init(_name, _symbol);
        __ERC721Burnable_init();
        __AccessControl_init();
    }

    function __ERC721Owl_init_unchained(address _admin, string memory baseURI_) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(URI_ROLE, _admin);
        baseURI = baseURI_;
    }

    /**
     * @notice Must have DEFAULT_ADMIN_ROLE
     * @dev Grants MINTER_ROLE to {a}
     * @param to address to
     */
    function grantMinter(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, to);
    }

    /**
     * @notice Must have DEFAULT_ADMIN_ROLE
     * @dev Grants URI_ROLE to {a}
     * @param to address to
     */
    function grantUriRole(address to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(URI_ROLE, to);
    }

    /***** MINTING *****/
    /**
     * @notice Must have MINTER_ROLE
     * @dev Allows MINTER_ROLE to mint NFTs
     * @param to address to
     * @param tokenId tokenId value
     */
    function mint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _mint(to, tokenId);
    }

    /**
     * @notice Must have MINTER_ROLE
     * @dev Allows caller to mint NFTs (safeMint)
     * @param to address to
     * @param tokenId tokenId value
     */
    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    /**
     * @notice Must have URI_ROLE role!
     * @dev Allows setting the baseURI
     * @param baseURI_ set the baseURI value.
     */
    function setBaseURI(string calldata baseURI_) public onlyRole(URI_ROLE) {
        baseURI = baseURI_;
    }

    /**
     * @dev Overrides OZ internal baseURI getter.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
}
