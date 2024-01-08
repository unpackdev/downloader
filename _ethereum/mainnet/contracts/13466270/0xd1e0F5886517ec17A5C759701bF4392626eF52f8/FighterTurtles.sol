// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract FighterTurtlesClub is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string private _baseURIPrefix;

    bool public presaleLive;
    bool public saleLive;
    
    uint256 public MaxSupply = 5555;

    uint private constant maxTokensPerTransaction = 10;
    uint private constant maxTokensPerPresale = 2;
    
    uint256 private publicPrice = 0.077 ether;
    uint256 private presalePrice = 0.055 ether;
    
    mapping(address => bool) public presalerList;
    mapping(address => uint256) public presalerListPurchases;

    address private _msig = 0xE03ad4fE1Ba744cF28E40B71939D8C9A8D104864;
    address private _donut = 0x2d0a8eB144153A4d68F52F7C62B285D788dd725B;

    constructor() ERC721("Fighter Turtles Club", "FTC") {}

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, totalSupply() + 1);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(_donut).transfer(balance * 2 / 5);
        payable(_msig).transfer(balance / 10);
        payable(msg.sender).transfer(address(this).balance);
    }
    
    //Can strictly only reduce supply!
    function reduceSupply(uint256 newMax) public onlyOwner {
            require(newMax < MaxSupply, "Value of new MaxSupply can not be higher than old value");
            require(newMax > totalSupply(), "Value of new MaxSupply can not be lower than existing supply");
            MaxSupply = newMax;
    }

   function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }

    function gift(address to,uint256 tokensNumber) public onlyOwner {
        require(tokensNumber + totalSupply() <= MaxSupply, "Tokens number to mint exceeds max tokens");
        for(uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(to, totalSupply() + 1);
        }
    }

    function buyPresale(uint tokensNumber) public payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(presalerList[msg.sender], "NOT_WHITELISTED");
        require(presalerListPurchases[msg.sender] + tokensNumber <= maxTokensPerPresale, "EXCEED_ALLOC");
        require(tokensNumber > 0, "Wrong amount");
        require(totalSupply() + tokensNumber <= MaxSupply, "Tokens number to mint exceeds number of mintable tokens");
        require(presalePrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        presalerListPurchases[msg.sender] = presalerListPurchases[msg.sender] + tokensNumber;

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function buyPublic(uint tokensNumber) public payable {
        require(saleLive, "PUBLIC_SALE_CLOSED");
        require(tokensNumber > 0, "Wrong amount");
        require(tokensNumber <= maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(totalSupply() + tokensNumber <= MaxSupply, "Tokens number to mint exceeds number of mintable tokens");
        require(publicPrice.mul(tokensNumber) <= msg.value, "Ether value sent is too low");

        for(uint i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

}