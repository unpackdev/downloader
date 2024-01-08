// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./Random.sol";
import "./LootRoom.sol";

library Errors {
    string constant internal OUT_OF_RANGE = "range";
    string constant internal NOT_OWNER = "owner";
    string constant internal ALREADY_CLAIMED = "claimed";
    string constant internal SOLD_OUT = "sold out";
    string constant internal INSUFFICIENT_VALUE = "low ether";
}

contract LootRoomToken is Ownable, Random, ERC721 {
    uint256 constant public AUCTION_BLOCKS = 6650;
    uint256 constant public AUCTION_MINIMUM_START = 1 ether;

    IERC721 immutable private LOOT;
    LootRoom immutable private RENDER;

    mapping (uint256 => bool) private s_ClaimedBags;

    uint256 private s_StartBlock;
    uint256 private s_StartPrice;
    uint256 private s_Lot;

    constructor(LootRoom render, IERC721 loot) ERC721("Loot Room", "ROOM") {
        RENDER = render;
        LOOT = loot;
        _startAuction(0);
    }

    function _generateTokenId() private returns (uint256) {
        return _random() & ~uint256(0xFFFF);
    }

    function _startAuction(uint256 lastPrice) private {
        uint256 oldLot = s_Lot;
        uint256 newLot = oldLot;
        while (newLot == oldLot) {
            // should never need to repeat, but without looping there's a tiny
            // chance the contract gets stuck trying to mint the same token id
            // repeatedly.
            newLot = _generateTokenId();
        }

        s_Lot = newLot;
        s_StartBlock = block.number;
        lastPrice *= 4;
        if (lastPrice < AUCTION_MINIMUM_START) {
            s_StartPrice = AUCTION_MINIMUM_START;
        } else {
            s_StartPrice = lastPrice;
        }
    }

    function getForSale() public view returns (uint256) {
        return s_Lot;
    }

    function getPrice() public view returns (uint256) {
        uint256 currentBlock = block.number - s_StartBlock;
        if (currentBlock >= AUCTION_BLOCKS) {
            return 0;
        } else {
            uint256 startPrice = s_StartPrice;
            uint256 sub = (startPrice * currentBlock) / AUCTION_BLOCKS;
            return startPrice - sub;
        }
    }

    function _buy(uint256 tokenId) private returns (uint256) {
        uint256 lot = s_Lot;
        require(0 == tokenId || tokenId == lot, Errors.SOLD_OUT);

        uint256 price = getPrice();
        require(msg.value >= price, Errors.INSUFFICIENT_VALUE);

        _startAuction(msg.value);

        return lot;
    }

    function safeBuy(uint256 tokenId) external payable returns (uint256) {
        tokenId = _buy(tokenId);
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function buy(uint256 tokenId) external payable returns (uint256) {
        tokenId = _buy(tokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function _claim(uint256 lootTokenId) private returns (uint256) {
        require(0 < lootTokenId && 8001 > lootTokenId, Errors.OUT_OF_RANGE);

        require(!s_ClaimedBags[lootTokenId], Errors.ALREADY_CLAIMED);
        s_ClaimedBags[lootTokenId] = true; // Claim before making any calls out.

        require(LOOT.ownerOf(lootTokenId) == msg.sender, Errors.NOT_OWNER);
        return _generateTokenId() | lootTokenId;
    }

    function safeClaim(uint256 lootTokenId) external returns (uint256) {
        uint256 tokenId = _claim(lootTokenId);
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function claim(uint256 lootTokenId) external returns (uint256) {
        uint256 tokenId = _claim(lootTokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

    function withdraw(address payable to) external onlyOwner {
        (bool success,) = to.call{value:address(this).balance}("");
        require(success, "failed");
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return RENDER.tokenURI(tokenId);
    }
}