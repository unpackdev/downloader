// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./ERC165Checker.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev ERC721 upgradable contract for Chubbicorns.
 */
contract Chubbicorns is OwnableUpgradeable, ERC721EnumerableUpgradeable {
    using ERC165Checker for address;

    string public constant NAME = "Chubbicorns";
    string public constant SYMBOL = "CHUB";
    uint256 public constant SUPPLY = 250;

    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address public proxyRegistryAddress;

    string public baseTokenURI;

    IERC1155 public openSeaStore; // 0x495f947276749ce646f68ac8c248420045cb7b5e for mainnet
    mapping(uint256 => uint256) public openSeaMapping; // Mapping of opensea id to erc721 id
    bool public mappingLocked;

    event ChubbicornMigrated(uint256 tokenId);

    function initialize(address _proxyRegistryAddress) public initializer {
        __Ownable_init();
        __ERC721Enumerable_init(NAME, SYMBOL, SUPPLY);
        proxyRegistryAddress = _proxyRegistryAddress;
        baseTokenURI = "https://app.chubbiverse.com/api/meta/chubbicorn/";
        mappingLocked = false;
    }

    modifier notLocked() {
        require(!mappingLocked, "OpenSea mapping is locked");
        _;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Set the base token URI.
     */
    function setBaseTokenURI(string memory newBaseTokenURI) public onlyOwner {
        baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev See {ERC721Upgradeable-_baseURI}
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Set the opensea token id to erc721 token id mapping.
     */
    function updateOpenSeaMapping(uint256[] calldata openSeaTokenIds, uint256[] calldata chubbicornIds)
        external
        onlyOwner
        notLocked
    {
        require(openSeaTokenIds.length == chubbicornIds.length, "Invalid mappings");
        unchecked {
            for (uint256 i = 0; i < openSeaTokenIds.length; i++) {
                openSeaMapping[openSeaTokenIds[i]] = chubbicornIds[i];
            }
        }
    }

    /**
     * @dev Set the open sea store.
     */
    function setOpenSeaStore(address openSeaStore_) external onlyOwner notLocked {
        require(openSeaStore_.supportsInterface(type(IERC1155).interfaceId), "Invalid opensea store");
        openSeaStore = IERC1155(openSeaStore_);
    }

    /**
     * @dev Lock the token id mapping and openSeaStore so they cannot be updated.
     */
    function lockMapping() external onlyOwner notLocked {
        mappingLocked = true;
    }

    /**
     * @dev Migrate chubbicorn from opensea to ERC721.
     * Requires approval of this contract on opensea store.
     */
    function enterChubbiverse(uint256 openSeaTokenId) external {
        uint256 tokenId = openSeaMapping[openSeaTokenId];
        require(tokenId > 0, "Token not eligible");
        require(!_exists(tokenId), "Token already claimed");

        _safeMint(_msgSender(), tokenId);
        openSeaStore.safeTransferFrom(_msgSender(), BURN_ADDRESS, openSeaTokenId, 1, "");
        emit ChubbicornMigrated(tokenId);
    }
}
