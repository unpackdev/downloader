// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

//     __    __  ______  __      __  ______  __  __         
//    /\ "-./  \/\  __ \/\ \    /\ \/\  == \/\ \/\ \        
//    \ \ \-./\ \ \  __ \ \ \___\ \ \ \  __<\ \ \_\ \       
//     \ \_\ \ \_\ \_\ \_\ \_____\ \_\ \_____\ \_____\      
//      \/_/  \/_/\/_/\/_/\/_____/\/_/\/_____/\/_____/      
//     ______  ______  __  __   ________  ______  ______    
//    /\  == \/\  == \/\ \/\ \ / /\  __ \/\__  _\/\  ___\   
//    \ \  _-/\ \  __<\ \ \ \ \'/\ \  __ \/_/\ \/\ \  __\   
//     \ \_\   \ \_\ \_\ \_\ \__| \ \_\ \_\ \ \_\ \ \_____\ 
//      \/_/    \/_/ /_/\/_/\/_/   \/_/\/_/  \/_/  \/_____/ 
//     ______  ______  ______  ______  __  __               
//    /\  == \/\  ___\/\  __ \/\  ___\/\ \_\ \              
//    \ \  __<\ \  __\\ \  __ \ \ \___\ \  __ \             
//     \ \_____\ \_____\ \_\ \_\ \_____\ \_\ \_\            
//      \/_____/\/_____/\/_/\/_/\/_____/\/_/\/_/                                           

contract MalibuPrivateBeach is ERC1155Supply, Ownable {

    string collectionURI = "";
    string private name_;
    string private symbol_; 
    uint256 public tokenQty;
    uint256 public currentTokenId;

    constructor() ERC1155(collectionURI) {
        name_ = "Malibu Private Beach";
        symbol_ = "MPB";
        tokenQty = 1;
        currentTokenId = 1;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    //=============================================================================
    // Private Functions
    //=============================================================================

    function privateMint(address account) public onlyOwner {
        _mint(account, currentTokenId, tokenQty, "");
        currentTokenId++;
    }

    function setCollectionURI(string memory newCollectionURI) public onlyOwner {
        collectionURI = newCollectionURI;
    }

    function getCollectionURI() public view returns(string memory) {
        return collectionURI;
    }

    function setTokenQty(uint256 qty) public onlyOwner {
        tokenQty = qty;
    }

    function setCurrentTokenId(uint256 id) public onlyOwner {
        currentTokenId = id;
    }

    //=============================================================================
    // Override Functions
    //=============================================================================
    
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 _tokenId) public override view returns (string memory) {
        return string(abi.encodePacked(collectionURI, Strings.toString(_tokenId), ".json"));
    }    
}
