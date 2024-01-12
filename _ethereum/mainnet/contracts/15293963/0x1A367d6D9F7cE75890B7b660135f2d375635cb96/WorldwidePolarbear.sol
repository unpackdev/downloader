// SPDX-License-Identifier: MIT
// Tells the Solidity compiler to compile only from v0.8.13 to v0.9.0
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

contract WorldwidePolarbear is Ownable, ERC721A, ReentrancyGuard{

    using Strings for uint256;

    constructor() ERC721A("WorldwidePolarbear","WWPB") {
    }

    uint256 private _totalSupply = 4000;

    function mint(uint256 amount) public onlyOwner{
        require(totalSupply() + amount <= _totalSupply, "Exceeds the total supply");
        _mint(msg.sender, amount);
    }

    bool private _blindBoxOpened = false;
    string private _blindTokenURI = "";
    string private baseTokenURI = "";

    function _baseURI() internal view override returns(string memory){
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)public view virtual override returns(string memory){
        require(_exists(tokenId), "URI query for nonexistent token");

        if(_blindBoxOpened){
            string memory baseURI = _baseURI();
            return bytes(baseURI).length > 0? string(abi.encodePacked(baseURI, tokenId.toString())): "";
        } else {
            return _blindTokenURI;
        }
    }

    function isBlindBoxOpened() public view returns(bool){
        return _blindBoxOpened;
    }
    function setBlindboxOpened(bool _status)public onlyOwner{
        _blindBoxOpened = _status;
    }

    function setBaseURI(string calldata uri) public onlyOwner{
        baseTokenURI = uri;
    }
    function setBlindURI(string calldata uri) public onlyOwner{
        _blindTokenURI = uri;
    }
}
