// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Base64.sol";

interface LootInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Multiverse is ERC721Enumerable, ReentrancyGuard, Ownable {
    // check for original holders
    LootInterface immutable Loot;
    LootInterface immutable Bloot;
    LootInterface LootDisplay;
    LootInterface BlootDisplay;

    // Mapping token ID to bloot/loot
    mapping(uint256 => uint8) _winningVariant;

    constructor(LootInterface _lootAddress, LootInterface _blootAddress)
        ERC721("Multiverse", "MULTILOOT")
    {
        Loot = _lootAddress;
        Bloot = _blootAddress;
        LootDisplay = _lootAddress;
        BlootDisplay = _blootAddress;
    }

    function changeDisplays(
        LootInterface _lootAddress,
        LootInterface _blootAddress
    ) public onlyOwner {
        LootDisplay = _lootAddress;
        BlootDisplay = _blootAddress;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (_winningVariant[tokenId] == 0) {
            return BlootDisplay.tokenURI(tokenId);
        } else {
            return LootDisplay.tokenURI(tokenId);
        }
    }

    // this will set the NFT to be a Loot claim (ie, display upside-down Bloot token)
    function mintWithLoot(uint256[] memory tokenIds, uint8 variant)
        public
        nonReentrant
    {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            require(
                Loot.ownerOf(tokenId) == _msgSender(),
                "You don't have the loot"
            );
            require(variant == 0 || variant == 1, "0 or 1 only");
            _safeMint(_msgSender(), tokenId);
            _winningVariant[tokenId] = variant;
        }
    }

    // this will set the NFT to be a Bloot claim (ie, display upside-down Loot token)
    function mintWithBloot(uint256[] memory tokenIds, uint8 variant)
        public
        nonReentrant
    {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            require(
                Bloot.ownerOf(tokenId) == _msgSender(),
                "You don't have the bloot"
            );
            require(variant == 0 || variant == 1, "0 or 1 only");
            _safeMint(_msgSender(), tokenId);
            _winningVariant[tokenId] = variant;
        }
    }

    // this will set the NFT to be a Loot claim (ie, display upside-down Bloot token)
    function changeToLoot(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            require(
                this.ownerOf(tokenId) == _msgSender(),
                "Need to have this NFT to change it"
            );
            _winningVariant[tokenId] = 1;
        }
    }

    // this will set the NFT to be a Bloot claim (ie, display upside-down Loot token)
    function changeToBloot(uint256[] memory tokenIds) public nonReentrant {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];
            require(
                this.ownerOf(tokenId) == _msgSender(),
                "Need to have this NFT to change it"
            );
            _winningVariant[tokenId] = 0;
        }
    }
}
