// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "./ERC721Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./MarketNode.sol";
import "./NFT721Metadata.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC165StorageUpgradeable.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is
    ERC165StorageUpgradeable,
    AccessControlUpgradeable,
    ERC721Upgradeable,
    MarketNode,
    NFT721Metadata
{
    using AddressUpgradeable for address;

    uint256 private nextTokenId;

    mapping(uint256 => uint256) public perkTransfer;

    event Minted(
        address indexed creator,
        uint256 indexed tokenId,
        string tokenPath
    );

    /**
     * @notice Gets the tokenId of the next NFT minted.
     */
    function getNextTokenId() public view returns (uint256) {
        return nextTokenId;
    }

    /**
     * @dev Called once after the initial deployment to set the initial tokenId.
     */
    function _initializeNFT721Mint() internal initializer {
        // Use ID 1 for the first NFT tokenId
        nextTokenId = 1;
    }

    /**
     * @notice Allows creators to mint an asset.
     */
    function mint(string memory tokenPath) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);
        _setTokenUriPath(tokenId, tokenPath);
        setApprovalForAll(getMarket(), true);
        emit Minted(msg.sender, tokenId, tokenPath);
    }

    /**
     * @notice Allows creators to mint perk.
     */
    function mintPerk(string memory tokenPath)
        external
        returns (uint256 tokenId)
    {
        tokenId = nextTokenId++;
        _mint(msg.sender, tokenId);
        _setTokenUriPath(tokenId, tokenPath);
        setApprovalForAll(getMarket(), true);
        perkTransfer[tokenId] = 1;
        emit Minted(msg.sender, tokenId, tokenPath);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721Upgradeable, NFT721Metadata)
    {
        if (perkTransfer[tokenId] > 0) {
            delete perkTransfer[tokenId];
        }
        super._burn(tokenId);
    }

    /**
     * @dev Explicit override to address compile errors.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165StorageUpgradeable,
            AccessControlUpgradeable,
            NFT721Metadata
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256[1000] private __gap;
}
