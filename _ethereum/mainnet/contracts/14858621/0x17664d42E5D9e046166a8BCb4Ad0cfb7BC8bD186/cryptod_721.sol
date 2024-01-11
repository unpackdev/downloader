// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract CryptoD721 is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    string public baseURI;

    function setBaseURI(string calldata uri_) public onlyOwner {
        baseURI = uri_;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId_.toString()));
    }

    mapping(address => bool) public minters;


    function setMinter(address newMinter_, bool bool_) public onlyOwner returns (bool) {
        minters[newMinter_] = bool_;
        return true;
    }

    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
    }


    Counters.Counter public _tokenId;

    function mint(address player_) public returns (bool) {
        require(minters[_msgSender()], "S: not minter's calling");
        _tokenId.increment();
        uint tokenId = _tokenId.current();
        _mint(player_, tokenId);

        return true;
    }

    function mintMulti(address player_, uint amount_) public returns (bool) {
        require(minters[_msgSender()], "S: not minter's calling");
        for (uint i = 0; i < amount_; ++i) {
            _tokenId.increment();
            uint tokenId = _tokenId.current();
            _mint(player_, tokenId);
        }
        return true;
    }

    uint public burned;

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "F: burner isn't owner");

        burned += 1;

        _burn(tokenId_);
        return true;
    }

    function burnMulti(uint[] calldata tokenIds_) public returns (bool){
        for (uint i = 0; i < tokenIds_.length; ++i) {
            burn(tokenIds_[i]);
        }
        return true;
    }
}
