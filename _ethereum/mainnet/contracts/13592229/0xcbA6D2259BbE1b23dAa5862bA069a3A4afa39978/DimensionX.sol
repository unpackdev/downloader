//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT

//DIMENSION X Comics Cards NFT Project
//Author: Devin Passage @martianarctic
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Whitelist.sol";

contract DimensionX is Context, ERC721, Whitelist {
    uint32 cardsIssued;     //total number of cards issued, which is used to check for an ultrarare card.
    uint32 cardCounter;     //which position of advancer we are currently on.
    uint32 cardId;          //this is the id of the next card that will be minted.
    uint256 mintingFee = 0.02 ether;
    enum WhitelistMode {
        off,
        free,
        required

    }
    WhitelistMode whitelist_mode = WhitelistMode.off;
    address payable public feeAddress;
    event CardMinted(address Recipient, uint256 tokenId);
    uint32[] advancer = [1,4,1,3,1,3,1,10,4,3,8,11,4,6]; //to enable our combination mechanic, we advance the next id by this amount to skip over cardIds that must be minted via combination.
    constructor() ERC721("DimensionX", "DMX") {
        
        feeAddress = payable(address(msg.sender));
        cardId = 1;
        cardCounter = 0;
        cardsIssued = 0;
    }
  
    function setFeeAddress(address payable FeeAddress) public onlyOwner {
        feeAddress = FeeAddress;
    }
    function getCardsIssued() public view returns (uint32) {
        return cardsIssued;
    }
    function doesCardExist(uint32 CardId) public view returns(bool) {
        return _exists(CardId);
    }
    function setMintingFee(uint256 Fee) public onlyOwner {
        mintingFee = Fee;
    }
    function sweepFunds() public onlyOwner {
        (bool success, ) = feeAddress.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    function setWhitelistMode(WhitelistMode NewMode) public onlyOwner {
        whitelist_mode = NewMode;
    }
    function getWhitelistMode() public view returns(WhitelistMode) {
        return whitelist_mode;
    }
    function _baseURI() internal pure override returns (string memory) {
        return "https://www.dimensionxnft.com/m/";
    }
    function mintFreeCard() public onlyWhitelisted {
        require(removeOwnAddressFromWhitelist(msg.sender));
        require(whitelist_mode == WhitelistMode.free, "free card mode disabled, no free cards at this time");
        _mintCard();
    }
    function mintCardFromWhitelist()
        public
        payable
        onlyWhitelisted
    {
        require(msg.value >= mintingFee, 'insufficient funds');
        _mintCard();
    }
    function mintCard()
        public
        payable
    {
        require(whitelist_mode == WhitelistMode.off, "whitelisting is on, please call mintCardFromWhitelist instead");
        require(msg.value >= mintingFee, 'insufficient funds');
        _mintCard();
    }
    function mintCards(uint32 NumberOfCards)
        public
        payable
    {   
        require(whitelist_mode == WhitelistMode.off, "whitelisting is on, please call mintCardFromWhitelist instead");
        require(NumberOfCards <= 10, "10 cards max only please");
        require(msg.value >= mintingFee*NumberOfCards, 'insufficient funds');
        for(uint32 i = 0; i < NumberOfCards; i++)
            _mintCard();
    }
    function _mintCard()
        internal
        
    {
        if(cardsIssued%225 == 14) {
            //starting with the 15th card, every 225 cards will be a foil mask card.
            //anyone may call getCardsIssued to see how close the next one is.
            //**ATTENTION: IMPORTANT DISCLOSURE**
            //it is impossible to guarantee you will get a foil mask card
            //so you should mint with the assumption you will *not* get one
            uint rareId = (cardsIssued/225)*960 + 59;
            _safeMint(msg.sender, rareId);
            emit CardMinted(msg.sender, rareId );
        }
        else {
            //normal mint, skips over cardids created by combos
            _safeMint(msg.sender, cardId);
            emit CardMinted(msg.sender, cardId );
            cardId += advancer[cardCounter];
            if(cardCounter == 13)
                cardCounter = 0;
            else
                cardCounter++;
        }
        cardsIssued++;
        //_forwardFunds();
    }
    function mintAnyCard(uint32 newCardId) public onlyOwner returns (uint32) {
        //we reserve the ability to mint cards that have been skipped by the program, for example, to make
        //something that would combine with might chimera, we need to mint a card that does not exist yet.
        require(newCardId < cardId, 'Can only call this to mint a card skipped by DimensionX');
        _safeMint(msg.sender, newCardId);
        emit CardMinted(msg.sender, newCardId );
        return newCardId;
    }
    function combineCards(uint32 inCardA, uint32 inCardB) public returns (uint32){
        //card combination logic
        require(ERC721.ownerOf(inCardA) == msg.sender, 'both cards must be owned by combiner');
        require(ERC721.ownerOf(inCardB) == msg.sender, 'both cards must be owned by combiner');
        require(inCardA == inCardB-1, 'must be adjacent cardids');
        _burn(inCardA);
        _burn(inCardB);
        uint32 newCardId = 0;
        if(inCardA % 15 == 1)
            newCardId = inCardA+15;
        else if(inCardA % 15 == 6)
            newCardId = inCardA+11;
        else if(inCardA % 15 == 10)
            newCardId = inCardA+26;
        else if(inCardA % 15 == 14)
            newCardId = inCardA+30;

        _safeMint(msg.sender, newCardId);
        emit CardMinted(msg.sender, newCardId );
        return cardId;
    }
    receive() external payable
    {
    }
}
