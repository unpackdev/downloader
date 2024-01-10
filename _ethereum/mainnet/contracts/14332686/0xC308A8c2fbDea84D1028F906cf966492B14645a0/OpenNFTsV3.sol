// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IOpenNFTs.sol";
import "./IOpenNFTsV3.sol";
import "./IERC173.sol";

/// @title OpenNFTs smartcontract
contract OpenNFTsV3 is
    IOpenNFTs,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    /// @notice Mint NFT allowed to everyone or only collection owner
    bool public open;

    /// @notice Burn NFT allowed or not
    bool public burnable;

    /// @notice onlyMinter, either everybody in open collection,
    /// @notice either only owner in specific collection
    modifier onlyMinter() {
        require(open || (owner() == _msgSender()), "Not minter");
        _;
    }

    /// @notice onlyBurner, only owner can burn if burnable
    modifier onlyBurner() {
        require(burnable, "Not burnable");
        require(owner() == _msgSender(), "Not owner");
        _;
    }

    /// @notice initialize
    /// @param name name of the NFT Collection
    /// @param symbol symbol of the NFT Collection
    /// @param owner owner of the NFT Collection
    /// @param options select minting open to everyone or only owner
    // solhint-disable-next-line comprehensive-interface
    function initialize(
        string memory name,
        string memory symbol,
        address owner,
        bool[] memory options
    ) external initializer {
        __Ownable_init();
        __ERC721_init(name, symbol);
        transferOwnership(owner);
        open = options[0];
        burnable = options[1];
    }

    /// @notice mint
    /// @param minter address of minter
    /// @param jsonURI json URI of NFT metadata
    function mintOpenNFT(address minter, string memory jsonURI)
        external
        override(IOpenNFTs)
        onlyMinter
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _safeMint(minter, newItemId);
        _setTokenURI(newItemId, jsonURI);

        return newItemId;
    }

    /// @notice burn NFT
    /// @param tokenId tokenID of NFT to burn
    function burnOpenNFT(uint256 tokenId) external override(IOpenNFTs) onlyBurner {
        _burn(tokenId);
    }

    /// @notice Get tokenURI
    /// @param tokenId tokenId of NFT
    /// @param tokenURI_ token URI of NFT
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory tokenURI_)
    {
        tokenURI_ = super.tokenURI(tokenId);
    }

    /// @notice test if this interface is supported
    /// @param interfaceId interfaceId to test
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IOpenNFTs).interfaceId ||
            interfaceId == type(IOpenNFTsV3).interfaceId ||
            interfaceId == type(IERC173).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }
}
