// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./EnumerableMapUpgradeable.sol";
import "./IPrivateSaleNft.sol";


contract PrivateSaleNft is ERC721EnumerableUpgradeable, UUPSUpgradeable, AccessControlUpgradeable, IPrivateSaleNft {
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.UintToUintMap;


    bytes32 public constant MINTER_MANAGER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    EnumerableMapUpgradeable.UintToUintMap internal _tokenMetadata;


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name_, string calldata symbol_, address privateSaleContract, address roleAdmin, address upgrader) initializer public {
        __AccessControl_init();
        __ERC721_init(name_, symbol_);  // we don't call because we want it pause
        _grantRole(MINTER_MANAGER_ROLE, privateSaleContract);
        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function mint(address to, uint inscribedTokens) override external onlyRole(MINTER_MANAGER_ROLE) {
        uint tokenId = totalSupply() + 1;
        _safeMint (to, tokenId);
        _tokenMetadata.set(tokenId, inscribedTokens);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function getTokenMetadata (uint256 tokenId) external view returns (bool, uint256) {
        return _tokenMetadata.tryGet(tokenId);
    }

    function _authorizeUpgrade(address) internal view override {
        if (!hasRole(UPGRADER_ROLE, msg.sender)) {
            revert NotUpgrader();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, IERC165Upgradeable, ERC721EnumerableUpgradeable) returns (bool) {
        return
        AccessControlUpgradeable.supportsInterface(interfaceId) ||
        ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override onlyRole(MINTER_MANAGER_ROLE) {
        ERC721Upgradeable._transfer(from, to, tokenId);
    }

}
