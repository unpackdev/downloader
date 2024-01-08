pragma solidity ^0.7.0;
// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";

contract NFTClub is ERC721, Ownable {
    using SafeMath for uint;

    enum CardType { STANDARD, PREMIUM }
    
    uint public constant MAX_STD_CARDS = 9000;
    uint public constant MAX_PREMIUM_CARDS = 1000;
    uint public constant MAX_STD_CARDS_PER_ACCOUNT = 1;
    uint public constant MAX_PREMIUM_CARDS_PER_ACCOUNT = 1;
    uint public constant MAX_PRE_SALE_PREMIUM_CARDS = 25;
    uint public constant PRE_SALE_DISCOUNT = 60;
    uint constant TREASURE_FEE = 60;
    uint public standardPrice;
    uint public premiumPrice;
    uint public totalStandard;
    uint public totalPremium;
    bool public hasSaleStarted = false;
    bool public hasPreSaleStarted = false;

    address treasureAddress;

    mapping(uint => string) cardNames;
    mapping(uint => CardType) cardTypes;
    
    event CardMinted(uint tokenId, address owner);
    event CardRenameRequested(uint tokenId, string cardName);
    event CardRenamed(uint tokenId, string cardName);
    event CardRenameFailed(uint tokenId);
    
    constructor(string memory baseURI, uint _stdPrice, uint _premiumPrice, address _treasureAddress) ERC721("The NFT Investors Club", "NFTCLUB") {
        setBaseURI(baseURI);
        standardPrice = _stdPrice;
        premiumPrice = _premiumPrice;
        treasureAddress = _treasureAddress;
    }
    
    function buyStandardCard() public payable {
        buyStandardCard(msg.sender);
    }
    
    function buyStandardCard(address receiver) public payable {
        require(hasSaleStarted, "sale hasn't started");
        require(cardsOfOwner(receiver, CardType.STANDARD) < MAX_STD_CARDS_PER_ACCOUNT, "account already have enouth standard cards");
        require(totalStandard < MAX_STD_CARDS, "the standard cards sale was sold out");
        require(msg.value >= standardPrice || msg.sender == owner(), "ether value sent is below the price");
        
        payable(treasureAddress).transfer(msg.value.mul(TREASURE_FEE).div(100));
        
        uint mintIndex = totalSupply();
        _safeMint(receiver, mintIndex);
        cardTypes[mintIndex] = CardType.STANDARD;
        totalStandard++;
        emit CardMinted(mintIndex, receiver);
    }
    
    function buyPremiumCard() public payable {
        buyPremiumCard(msg.sender);
    }
    
    function buyPremiumCard(address receiver) public payable {
        require(hasSaleStarted || hasPreSaleStarted, "sale hasn't started");
        require(hasSaleStarted || totalPremium < MAX_PRE_SALE_PREMIUM_CARDS, "pre sale has ended");
        require(cardsOfOwner(receiver, CardType.PREMIUM) < MAX_PREMIUM_CARDS_PER_ACCOUNT, "account already have enouth premium cards");
        require(totalPremium < MAX_PREMIUM_CARDS, "the premium cards sale was sold out");

        uint currentPrice = !hasSaleStarted && hasPreSaleStarted ? premiumPrice.sub(premiumPrice.mul(PRE_SALE_DISCOUNT).div(100)) : premiumPrice;
        require(msg.value >= currentPrice || msg.sender == owner(), "ether value sent is below the price");
        
        payable(treasureAddress).transfer(msg.value.mul(TREASURE_FEE).div(100));
        
        uint mintIndex = totalSupply();
        _safeMint(receiver, mintIndex);
        cardTypes[mintIndex] = CardType.PREMIUM;
        totalPremium++;
        emit CardMinted(mintIndex, receiver);
    }
    
    function tokensOfOwner(address _owner) public view returns(uint[] memory ) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function cardsOfOwner(address _owner, CardType cardType) public view returns(uint) {
        uint count;
        uint[] memory userTokens = tokensOfOwner(_owner);
        uint index;
        for (index = 0; index < userTokens.length; index++) {
            if (cardTypes[userTokens[index]] == cardType) {
                count++;
            }
        }
        
        return count;
    }
    
    function cardName(uint tokenId) public view returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return cardNames[tokenId];
    }
     
    function renameCardRequest(uint tokenId, string memory _cardName) public {
        require(msg.sender == ownerOf(tokenId), "sender does not have the current card");
        emit CardRenameRequested(tokenId, _cardName);
    }
    
    function renameCard(uint tokenId, string memory _cardName) external onlyOwner {
        cardNames[tokenId] = _cardName;
        emit CardRenamed(tokenId, _cardName);
    }
    
    function failRenameCard(uint tokenId) external onlyOwner {
        emit CardRenameFailed(tokenId);
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function setTreasureAddress(address _treasureAddress) public onlyOwner {
        treasureAddress = _treasureAddress;
    }
    
    function setStandardPrice(uint _standardPrice) public onlyOwner {
        standardPrice = _standardPrice;
    }
    
    function setPremiumPrice(uint _premiumPrice) public onlyOwner {
        premiumPrice = _premiumPrice;
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function startPreSale() public onlyOwner {
        hasPreSaleStarted = true;
    }

    function pausePreSale() public onlyOwner {
        hasPreSaleStarted = false;
    }
    
    function withdraw(uint amount) public onlyOwner {
        require(amount <= address(this).balance, "not enouth ether in balance");
        require(payable(msg.sender).send(amount));
    }
    
    function withdrawAll() public onlyOwner {
        withdraw(address(this).balance);
    }
    
    function tokenURI(uint tokenId) public view override returns (string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI(), cardTypes[tokenId] == CardType.PREMIUM ? "premium" : "standard", "/", uint2str(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if(_exists(tokenId)) {
            require(cardTypes[tokenId] == CardType.STANDARD || cardsOfOwner(to, CardType.PREMIUM) < MAX_PREMIUM_CARDS_PER_ACCOUNT, "receiver already have enouth premium cards");
            require(cardTypes[tokenId] == CardType.PREMIUM || cardsOfOwner(to, CardType.STANDARD) < MAX_STD_CARDS_PER_ACCOUNT, "receiver already have enouth standard cards");
        }
        
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function uint2str(uint _i) internal pure returns (string memory str) {
        if (_i == 0){
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0){
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}