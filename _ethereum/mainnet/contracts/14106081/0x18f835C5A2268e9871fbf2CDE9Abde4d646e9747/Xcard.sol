// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./erc721.sol";
import "./utils.sol";
import "./IEns.sol";

struct Colorable {
    string color;
}

struct ColorWithPattern {
    string color;
    uint pattern;
}

struct CardSkin {
    Colorable cockade;
    Colorable cufflink;
    Colorable epaulet;
    Colorable bordure;
    ColorWithPattern blazon;
    uint256 tokenId;
    uint256 gene; //shoud be unique
    bool primary;
}

contract Xcard is ERC721Enumerable, ReentrancyGuard, Ownable, EnsOwnable {
    
    string[5] kColors =  [
        "blue",
        "green",
        "purple",
        "epic",
        "rare"
    ];

    uint[5] kPatterns = [1, 2, 3, 4, 5];

    uint256 lastTokenId;
    uint256 seed;
    uint256 price;
    uint256 poolSize;
    mapping(address => bool) invitationList;
    mapping(uint256 => uint256) cardGenes;
    mapping(address => uint256) primaryCards;
    uint256[62] tokenBitmaps;
    bool disableInvitationList;
 
    function disableEnsCheck() public onlyOwner() {
        requireENS = false;
    }

    function makeSkinByGene(uint256 gene) view internal returns (CardSkin memory) {
        CardSkin memory card;
        uint256 rnd = gene;
        card.cockade.color = kColors[rnd % kColors.length]; 
        rnd /= kColors.length;
        card.cufflink.color = kColors[kColors.length - 1 - rnd % kColors.length];
        rnd /= kColors.length;
        card.epaulet.color = kColors[rnd % kColors.length];
        rnd /= kColors.length;
        card.bordure.color = kColors[kColors.length - 1 - rnd % kColors.length];
        rnd /= kColors.length;
        card.blazon.color = kColors[rnd % kColors.length];
        rnd /= kColors.length;
        card.blazon.pattern = kPatterns[rnd % kPatterns.length];
        return card;
    }

    function takeRandomGene() internal returns (uint256) {
        require(tokenBitmaps.length > 0, "no more space for bitmap");
        //pick random row to start checking
        uint256 rowIndex = random(tokenBitmaps.length);
        uint256 si = rowIndex;
        do {
                uint256 row = tokenBitmaps[si];
                //find a free bit slot
                for(uint i=0;i<256;i++) {
                    if ( (1<<i & row) == 0) {
                        tokenBitmaps[rowIndex] = row | 1<<i;
                        return rowIndex * 256 + i;
                    }
                }
                si = (si + 1) % tokenBitmaps.length; //not found, so check the next row
        }while(si != rowIndex);
        revert("no more free slots");
    }

    function mint() public payable nonReentrant onlyEnsOwner {
        require(poolSize>0, "no more tokens");
        if (!disableInvitationList) {
            require(invitationList[msg.sender], "address not invited");
        }
        if (price > 0) {
            require(msg.value >= price, "paid not enough");
        }
        require(balanceOf(msg.sender) == 0, "at most one card for each account");
        uint256 tokenId = lastTokenId + 1;
        cardGenes[tokenId] = takeRandomGene();
        lastTokenId++;
        poolSize--;
        _safeMint(_msgSender(), tokenId);
    }

    function queryCard(uint256 tokenId) public view returns (CardSkin memory) {
        require(tokenId > 0, "invalid tokenid");
        require(tokenId <= lastTokenId, "token not minted");
        uint256 gene = cardGenes[tokenId];
        CardSkin memory card = makeSkinByGene(gene);
        card.tokenId = tokenId;
        card.gene = gene;
        return card;
    }

    function queryPrimaryCard(address user) public view returns (CardSkin memory) {
        uint256 cardsCount = balanceOf(user);
        require(cardsCount > 0, "no cards");
        uint256 prim = primaryCards[user];
        if (prim == 0) {
            prim = tokenOfOwnerByIndex(user, cardsCount - 1);
        }
        return queryCard(prim);
    }

    //Withdraw out money in contract, admin only
    function withdrawETH(address payable recv) public onlyOwner {
        recv.transfer(address(this).balance);
    }

    function random(uint256 upper) internal returns (uint256) {
        seed = uint256(keccak256(abi.encodePacked(seed,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty)));
        return seed % upper;
    }
    
    function queryCardsByAddress(address user) public view returns (CardSkin[] memory) {
        uint256 tokenCount = balanceOf(user);
        CardSkin[] memory cards = new CardSkin[](tokenCount);
        uint256 primaryTokenId = primaryCards[user];
        for(uint i=0; i<tokenCount; i++) {
          uint256 tokenId = tokenOfOwnerByIndex(user, i);
          CardSkin memory card = queryCard(tokenId);
          if (primaryTokenId == tokenId) {
            card.primary = true;
          }
          cards[i] = card;
        }
        return cards;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (primaryCards[from] == tokenId) {
            delete primaryCards[from];
        }
    }

    function setPrimary(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "only token owner");
        primaryCards[msg.sender] = tokenId;
    }

    function publish(uint amount, address[] calldata invitationListAddr) public onlyOwner {
        poolSize += amount;
        require(poolSize + totalSupply() <= 15625, "at most 15625");
        for(uint i=0; i< invitationListAddr.length; i++) {
            invitationList[invitationListAddr[i]] = true;
        }
    }

    function setPrice(uint256 priceUpdate) public onlyOwner {
        price = priceUpdate;
    }

    function enableEveryone() public onlyOwner() {
        disableInvitationList = true;
    }

    function getPoolInfo() public view returns(uint256, uint256) {
        return (poolSize, totalSupply());
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[6] memory parts;
        parts[0] = "https://api.xpassport.app/token/";
        parts[1] = Utils.uint2str(tokenId);
        parts[2] = "?network=";
        parts[3] = Utils.getNetwork();
        parts[4] = "&address=";
        parts[5] = Utils.addr2str(address(this));
        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]));
    }

    constructor() ERC721("Xcard", "XCD") Ownable() {}

}
