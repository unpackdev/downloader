// SPDX-License-Identifier: MIT
// Developer: @Brougkr

pragma solidity ^0.8.4;
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract Moonopoly is ERC1155, Ownable, Pausable, ERC1155Burnable
{
    using SafeMath for uint256;

    //Initialization
    string public constant name = "Moonopoly";
    string public constant symbol = "MOON";
    string public _BASE_URI = "https://ipfs.io/ipfs/QmVtiErs3McktXqkXC3uQ4XfNz9aCTtEAuQ5fTZXLjhrFE/";
    
    //Token Amounts
    uint256 public _CARDS_MINTED = 1;
    uint256 public _MAX_CARDS = 5555;
    uint256 public _MAX_CARDS_PURCHASE = 5;
    
    //Price
    uint256 public _CARD_PRICE = 0.03 ether;

    //Sale State
    bool public _SALE_IS_ACTIVE = false;
    bool public _ALLOW_MULTIPLE_PURCHASES = false;

    //Mint Mapping
    mapping (address => bool) private minted;

    constructor() ERC1155("https://ipfs.io/ipfs/QmVtiErs3McktXqkXC3uQ4XfNz9aCTtEAuQ5fTZXLjhrFE/{id}.json") 
    {
        _mint(msg.sender, 0, 555, ""); //Founding 555 Airdrop
    }

    //URI for decoding storage of tokenIDs
    function uri(uint256 tokenId) override public view returns (string memory) { return(string(abi.encodePacked(_BASE_URI, Strings.toString(tokenId), ".json"))); }

    //Mints Moonopoly Cards
    function MoonopolyMint(uint numberOfTokens) public payable
    {
        require(_SALE_IS_ACTIVE, "Sale must be active to mint Cards");
        require(numberOfTokens <= _MAX_CARDS_PURCHASE, "Can only mint 5 Cards at a time");
        require(_CARDS_MINTED.add(numberOfTokens) <= _MAX_CARDS, "Purchase would exceed max supply of Cards");
        require(_CARD_PRICE.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct. 0.03 ETH Per Card | 30000000000000000 WEI");
        if(!_ALLOW_MULTIPLE_PURCHASES) { require(!minted[msg.sender], "Address Has Already Minted"); }

        //Mints Cards
        for(uint i = 0; i < numberOfTokens; i++) 
        {
            if (_CARDS_MINTED <= _MAX_CARDS) 
            {
                _mint(msg.sender, _CARDS_MINTED, 1, "");
                _CARDS_MINTED += 1;
            }
        }
        minted[msg.sender] = true;
    }
    
    //Conforms to ERC-1155 Standard
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override 
    { 
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); 
    }

    //Batch Transfers Tokens
    function __batchTransfer(address[] memory recipients, uint256[] memory tokenIDs, uint256[] memory amounts) public onlyOwner 
    { 
        for(uint i=0; i < recipients.length; i++) 
        { 
            _safeTransferFrom(msg.sender, recipients[i], tokenIDs[i], amounts[i], ""); 
        }
    }

    //Sets Base URI For .json hosting
    function __setBaseURI(string memory BASE_URI) public onlyOwner { _BASE_URI = BASE_URI; }

    //Sets Max Cards for future Card Expansion Packs
    function __setMaxCards(uint256 MAX_CARDS) public onlyOwner { _MAX_CARDS = MAX_CARDS; }

    //Sets Max Cards Purchaseable by Wallet
    function __setMaxCardsPurchase(uint256 MAX_CARDS_PURCHASE) public onlyOwner { _MAX_CARDS_PURCHASE = MAX_CARDS_PURCHASE; }

    //Sets Future Card Price
    function __setCardPrice(uint256 CARD_PRICE) public onlyOwner { _CARD_PRICE = CARD_PRICE; }

    //Flips Allowing Multiple Purchases for future Card Expansion Packs
    function __flip_allowMultiplePurchases() public onlyOwner { _ALLOW_MULTIPLE_PURCHASES = !_ALLOW_MULTIPLE_PURCHASES; }
    
    //Flips Sale State
    function __flip_saleState() public onlyOwner { _SALE_IS_ACTIVE = !_SALE_IS_ACTIVE; }

    //Withdraws Ether from Contract
    function __withdraw() public onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    //Pauses Contract
    function __pause() public onlyOwner { _pause(); }

    //Unpauses Contract
    function __unpause() public onlyOwner { _unpause(); }
}