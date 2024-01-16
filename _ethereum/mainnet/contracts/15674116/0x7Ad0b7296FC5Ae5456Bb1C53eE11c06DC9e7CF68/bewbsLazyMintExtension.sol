// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
__/\\\\\\\\\\\\\_____________________________________/\\\_____________________        
 _\/\\\/////////\\\__________________________________\/\\\_____________________       
  _\/\\\_______\/\\\__________________________________\/\\\_____________________      
   _\/\\\\\\\\\\\\\\______/\\\\\\\\___/\\____/\\___/\\_\/\\\_________/\\\\\\\\\\_     
    _\/\\\/////////\\\___/\\\/////\\\_\/\\\__/\\\\_/\\\_\/\\\\\\\\\__\/\\\//////__    
     _\/\\\_______\/\\\__/\\\\\\\\\\\__\//\\\/\\\\\/\\\__\/\\\////\\\_\/\\\\\\\\\\_   
      _\/\\\_______\/\\\_\//\\///////____\//\\\\\/\\\\\___\/\\\__\/\\\_\////////\\\_  
       _\/\\\\\\\\\\\\\/___\//\\\\\\\\\\___\//\\\\//\\\____\/\\\\\\\\\___/\\\\\\\\\\_ 
        _\/////////////______\//////////_____\///__\///_____\/////////___\//////////__
 */
/// @author: bewbs.fans

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC721.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./ERC165.sol";

contract bewbsLazyMintExtension is AdminControl, ICreatorExtensionTokenURI {
    using Strings for uint256;

    using Counters for Counters.Counter;
    address private _creator;
    string private _baseURI;
    Counters.Counter private _totalSupply;
    uint256 private maxSupply = 8008;
    uint256 private reserve = 888;
    uint256 private price = 0.08 ether;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function reserveExists() public view virtual returns (bool) {
        return reserve > _totalSupply.current();
    }

    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply.current();
    }

    function mint(uint256 num) public payable {
        uint256 supply = _totalSupply.current();
        require(num <= 8, "You can mint a maximum of 8 bewbs");
        require(supply + num <= maxSupply, "Exceeds maximum bewbs supply");
        require(
            (reserveExists() && num == 1) || msg.value >= price * num,
            "Ether sent is not correct"
        );

        for (uint256 i; i < num; i++) {
            IERC721CreatorCore(_creator).mintExtension(msg.sender);
            _totalSupply.increment();
        }
    }

    function setBaseURI(string memory baseURI) public adminRequired {
        _baseURI = baseURI;
    }

    function tokenURI(address creator, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(creator == _creator, "Invalid token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}
