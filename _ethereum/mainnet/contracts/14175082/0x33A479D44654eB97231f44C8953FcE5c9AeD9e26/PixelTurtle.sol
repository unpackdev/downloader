// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract PixelTurtle is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    using Strings for uint256;
    using SafeMath for uint256;
    
    uint public price;
    uint public presalePrice;
    mapping (address => bool) private whitelist;
    mapping(address => bool) purchased;
    mapping (address => uint) private _numberOfWallets;

    uint256 public MAX_TOKENS = 8888;
    string [] private URLs;
    string [] private reserved;
    bool public presaleEnabled = false;
    bool public saleEnabled = false;
    uint private counter = 51;
    uint private pcounter = 1;
    uint private currentID = 51;

    uint public preSaleAllowedMaxTokens = 1;
    uint public saleAllowedTokens = 10;


    address private turtleWallet = 0xED5A935aA9e40973CbC901E52a86175035C96ad1;
    address private BrkWallet = 0xf60F4Ab1259a3212e1fec485724122636Bce7a99;

    constructor() ERC721("PIXEL TURTLE CLUB", "PTC"){
    }


    function setWhitelist(address[] memory _wallets) public onlyOwner {
            for(uint i = 0; i < _wallets.length; i++) {
                    whitelist[_wallets[i]] = true;
            }
    }
    
    function setReserved(string[] memory _reserved) public onlyOwner {
        reserved = _reserved;
    }

    function setURLS(string[] memory _URLs) public onlyOwner {
        URLs = _URLs;
    }

    function setPrice(uint _price) public onlyOwner{
        price = _price;
    }
    
    function setPresalePrice(uint _preprice) public onlyOwner{
        presalePrice = _preprice;
    }
    
    function enablePresale(bool sale) public onlyOwner{
        presaleEnabled = sale;
    }

    function enableSale(bool sale) public onlyOwner{
        saleEnabled = sale;
    }
    function _baseURI() internal pure override  returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/QmXWsDfM3U63w8f9o31Q25WeBrqQ5kNBsu9Sqn5y9ne9NR/";
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(Strings.toString(tokenId), ".json")));
    }
    function reservedMint() public onlyOwner{
        require(pcounter <= 50, "MAX TOKEN MINTED");
        uint tempPcounter = pcounter;
        pcounter += 1;
        safeMint(msg.sender, tempPcounter);
    }

    function presaleMint() public payable{
        require (counter <= 500, "Exceeded max than 500, presale not available");
        require(msg.value >= presalePrice, "You need to pay the appropriate amount");
        require(presaleEnabled == true, "Presale not enabled");
        require(whitelist[msg.sender], "You are not whitelisted");

        require(purchased[msg.sender] == false, "Already purchased");
        purchased[msg.sender] = true;
        _numberOfWallets[msg.sender]+= 1;
        uint tempCurrentId = currentID;
        currentID += 1;
        counter += 1;
        _safeMint(msg.sender, tempCurrentId);
        _setTokenURI(tempCurrentId, string(abi.encodePacked(Strings.toString(tempCurrentId), ".json")));
    }
    function publicMint(uint amount) public payable{
        require (saleEnabled == true, "Sale not enabled");
        require(_numberOfWallets[msg.sender] + amount <= saleAllowedTokens, "Excedeed number of purchased tokens for presale per wallet");
        require (msg.value >= price * amount, "You need to pay the appropriate amount");
        require (amount <= 3, "You cannot purchase more than 3 NFT");
        require (MAX_TOKENS >= currentID + amount, "Not enough remaining");
        for (uint i = 1; i <= amount; i++){
            uint tempCurrentId = currentID;
            currentID += 1;
            counter += 1;
            _safeMint(msg.sender, tempCurrentId);
            _setTokenURI(tempCurrentId, string(abi.encodePacked(Strings.toString(tempCurrentId), ".json")));
            _numberOfWallets[msg.sender] = _numberOfWallets[msg.sender] + 1;
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance!");
        payable(BrkWallet).transfer(balance.div(100).mul(10));
        payable(turtleWallet).transfer(balance.div(100).mul(90));
    }
}

