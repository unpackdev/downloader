// SPDX-License-Identifier: MIT

//   _  __             _                    
//  | |/ /__ _ ___ ___(_) ___  _ __   __ _  
//  | ' // _` / __/ __| |/ _ \| '_ \ / _` | 
//  | . \ (_| \__ \__ \ | (_) | | | | (_| | 
//  |_|\_\__,_|___/___/_|\___/|_| |_|\__,_| 



pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";

contract KassionaHead is ERC721Enumerable,ERC721Burnable, Ownable {

    enum Rarity {Legendary,Epic,Rare,Common }
    enum Property {Ubinooa,Kiwanna,Busterra }

    uint256 public constant maxTokenSupply = 7779;

    uint public constant privateSaleTime = 1664334000 ;
    uint public constant publicSaleTime = 1664550000;
    
    string private _baseURIextended;

    mapping(address => bool) public whiteList;
    mapping(address => uint) private mintedPerAddress;
    mapping(uint => uint) private _availableTokens;

    address public admin; 

    constructor() ERC721("BoovsHEAD", "KABH") {
    }

    function ownerMint(uint256 tokenId) external onlyOwner {
        _safeMint(_msgSender(),tokenId);

        uint256 lastIndex = maxTokenSupply-totalSupply();
        _availableTokens[tokenId] = lastIndex;
    }


    function mint() external{
        require(block.timestamp > privateSaleTime, "Not time for mint");
        require(totalSupply() + 1 <= maxTokenSupply, "Cannot exceed total supply");

        if(block.timestamp > publicSaleTime) {
            require(mintedPerAddress[_msgSender()] + 1 <= 1, "Cannot exceed max mint per wallet");
        }else {
            require(mintedPerAddress[_msgSender()] + 1 <= 2, "Cannot exceed max mint per wallet");
            require(whiteList[msg.sender],"Only mint for white list now");
        }
        mintedPerAddress[_msgSender()] += 1;

        _safeMint(_msgSender(),_getRandomTokenToMint());
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function addWhiteList(address[] memory addrs) external onlyOwner{
        for(uint i=0;i<addrs.length;i++) {
            whiteList[addrs[i]] = true;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function isApprovedForAll(address account, address operator) public view override(ERC721, IERC721) returns (bool) {
        if (operator == admin) {
            return true;
        }

        return super.isApprovedForAll(account, operator);
    }

    function setAdmin(address admin_) external onlyOwner{
        admin = admin_;
    }

    function tokenProperty(uint256 tokenId) external pure returns (uint8){
        if(tokenId>=1 && tokenId<=2593) {
            return uint8(Property.Ubinooa);
        }else if(tokenId<=5186){
            return uint8(Property.Kiwanna);
        }else{
            return uint8(Property.Busterra);
        }
    }

    function tokenRarity(uint256 tokenId) external pure returns (uint8){
        uint256 propertyIndex = (tokenId-1)%2593 + 1;
        if(propertyIndex>=1 && propertyIndex<=3) {
            return uint8(Rarity.Legendary);
        }else if(propertyIndex<=133){
            return uint8(Rarity.Epic);
        }else if(propertyIndex<=833){
            return uint8(Rarity.Rare);
        }else{
            return uint8(Rarity.Common);
        }
    }

    function tokenURIsOfOwner(address owner) public view  returns (string[] memory) {
        uint balance = balanceOf(owner); 
        string[] memory ret = new string[](balance);
        for(uint i=0;i<balance;i++) {
            ret[i] = tokenURI(tokenOfOwnerByIndex(owner, i));
        }
        return ret;
    }

    function tokenIdsOfOwner(address owner) public view  returns (uint256[] memory) {
        uint balance = balanceOf(owner); 
        uint256[] memory ret = new uint256[](balance);
        for(uint i=0;i<balance;i++) {
            ret[i] = tokenOfOwnerByIndex(owner, i);
        }
        return ret;
    }

    function _random() private view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,totalSupply())));
    }

    // fisher–yates shuffle algorithm
    function _getRandomTokenToMint() private returns (uint256) {
        uint256 indexToUse = _random()%(maxTokenSupply-totalSupply());

        uint256 valAtIndex = _availableTokens[indexToUse];
        if(valAtIndex==0) {
            valAtIndex = indexToUse;
        }

        uint256 lastIndex = maxTokenSupply-totalSupply()-1;

        if(indexToUse!=lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
                if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
            }
        }

        return valAtIndex+1;
    } 
}