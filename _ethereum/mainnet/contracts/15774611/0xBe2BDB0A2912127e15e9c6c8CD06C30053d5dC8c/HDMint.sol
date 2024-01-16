/*
 888    888 8888888888 8888888888 8888888b.         d8888      8888888b. 8888888 .d8888b.  8888888 88888888888     d8888 888      
 888    888 888        888        888   Y88b       d88888      888   "88b  888  d88P  Y88b   888       888        d88888 888      
 888    888 888        888        888    888      d88P888      888    888  888  888    888   888       888       d88P888 888      
 8888888888 8888888    8888888    888   d88P     d88P 888      888    888  888  888          888       888      d88P 888 888      
 888    888 888        888        8888888P"     d88P  888      888    888  888  888  88888   888       888     d88P  888 888      
 888    888 888        888        888 T88b     d88P   888      888    888  888  888    888   888       888    d88P   888 888      
 888    888 888        888        888  T88b   d8888888888      888  .d88P  888  Y88b  d88P   888       888   d8888888888 888      
 888    888 8888888888 8888888888 888   T88b d88P     888      8888888P" 8888888 "Y8888P88 8888888     888  d88P     888 88888888 

 * Written by:
 * 1) Mike Johnston
 * github: 0xmeowdy
 * email: mike@heera.digital

 * 2) Syed Muhammad Ali
 * github: SyedAli00896
 * email: syedali00896@gmail.com
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12 <0.9.0;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";

error InvalidURI();

/**
 * @notice Heera Digital brings digital rights management, IP protection, asset uniqueness intelligence,
 * anti-theft and key loss protection, succession planning, and much more to the NFT universe.
 * @dev HDMint contract for minting NFTs on Heera Digital
 * Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HDMint is
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    uint256 private _currentIndex;
    string public baseURI;

    event Mint(address indexed buyer, uint256 id, string uri);

    function initialize() public initializer {
        __ERC721_init("HeeraDigital", "HD");
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
        __Pausable_init();
        baseURI = "ipfs://";
    }

    /**********************
     * External Functions *
     **********************/

    /*
     * Pause contract from minting
     */
    // solhint-disable-next-line
    function pause() external onlyOwner {
        _pause();
    }

    /*
     * Unpause contract for minting
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Mints Heera NFTs
     * @param _to The address where the user wants to mint
     * @param _uri The uri where the asset is stored
     */
    function safeMint(address _to, string calldata _uri) external {
        if (bytes(_uri).length == 0) revert InvalidURI();
        uint256 tokenId = ++_currentIndex;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
        emit Mint(_to, tokenId, _uri);
    }

    /*
     * Sets up base URI
     */
    function setBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    /**
     * @notice Query number of tokens minted.
     */
    function totalMinted() external view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @notice Query all tokens owned by an address.
     * @param _owner The address of wallet owner
     */
    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    /**********************
     * Public Functions *
     **********************/

    /**
     * @notice Allows to get the complete URI of a specific token by its ID
     * @param _tokenId The id of the token
     * @return URI of the token which has _tokenId Id
     * @inheritdoc ERC721Upgradeable
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _burn(uint256 _tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(_tokenId);
    }

    /**
     * @inheritdoc ERC721Upgradeable
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {}
}
