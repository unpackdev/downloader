// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract HeroesFollowHeroes is ERC1155Burnable, Ownable  {

	string public name_;
	string public symbol_;

    constructor(
        string memory _name, 
        string memory _symbol,  
        string memory _uri
    ) ERC1155(_uri) {
        name_ = _name;
        symbol_ = _symbol;

        _mint(msg.sender, 0, 1651, "");
    } 

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }     
}
