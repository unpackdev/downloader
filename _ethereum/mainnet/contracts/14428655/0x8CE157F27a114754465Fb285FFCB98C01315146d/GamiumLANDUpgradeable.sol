// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./Initializable.sol";

contract GamiumLANDUpgradeable is Initializable, ERC721Upgradeable, ERC721URIStorageUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    string private _baseURIextended;

    uint32 public minted; // LANDs minted
    uint32 public cap; // max LANDs that can be minted

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __ERC721_init("Gamium LANDs", "LAND");
        __ERC721URIStorage_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();

        _baseURIextended = "https://gamium.world/lands/";
        cap = 65536; // max LANDs that can be minted
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function safeMint(address to, uint256 tokenId)
        external
        onlyOwner
    {
        require(minted < cap, "LAND: Max LANDs have been minted");
        minted += 1;

        _safeMint(to, tokenId);
    }

    function safeBatchMint(address[] calldata to, uint256[] calldata tokenId)
        external
        onlyOwner
    {
        uint32 toMint = uint32(to.length);
        require(to.length == tokenId.length, "LAND: Differents lenghts between to and tokenId");
        require(minted + toMint - 1 < cap, "LAND: Max LANDs have been minted");
        minted += toMint;

        for (uint i = 0; i < toMint; i++) {
            _safeMint(to[i], tokenId[i]);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        string memory _idBaseURI= super.tokenURI(tokenId);
        return string(abi.encodePacked(_idBaseURI, "/metadata.json"));
    }
}