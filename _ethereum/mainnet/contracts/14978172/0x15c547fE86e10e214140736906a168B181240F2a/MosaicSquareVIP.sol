/*

                                                                                             ,,,

   ██████      ,██████                                                                    ▄███████
   ███████    ╔███████                                                                   ⌠█████████
   ████████▄ █████████    ,▄███████▄     ,▄████████▄   ,▄█████████µ   ▐████▌    ▄██████   ,▄██j████
   ███████████████████  ,█████████████  ╒█████▀▀████    ▀███▀▀██████  ▐████▌  ▄████████  ┌████j████
   ████▌ ██████▀ █████  █████     █████ ╟██████▄╖,        ,,,, ╟████b  ,,,,  ▐████▌
   ████▌  ╙███   █████  ████▌     ╟████  ╙▀█████████▄  ▄████████████b ▐████▌ ╟████▄
   ████▌    ▀    █████  █████▄,,,▄████▌  ╓█╓   ╙█████ ▐████    ╞████b ▐████▌  ██████▄▄███╖
   ████▌         █████   ╙███████████▀  ████████████▀  █████████████b ▐████▌   ▀█████████▀
   ▀▀▀▀¬         ▀▀▀▀▀      ╙▀▀▀▀▀╙       `▀▀▀▀▀▀▀      ╙▀▀▀▀▀ └▀▀▀▀  '▀▀▀▀       ╙▀▀▀▀

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract MosaicSquareVIP is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    address public owner;
    uint256 public maxTotalSupply;
    Counters.Counter private _tokenIdCounter;

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    constructor(address ownerAddress) ERC721("MosaicSquare VIP,", "MSVIP") {
        maxTotalSupply = 200;
        Counters.reset(_tokenIdCounter);
        owner = ownerAddress;
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        require(Counters.current(_tokenIdCounter) < maxTotalSupply, "MosaicSquareVIP: max total supply reached");

        Counters.increment(_tokenIdCounter);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

    function totalSupply() public view returns (uint256) {
        return Counters.current(_tokenIdCounter);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyOwner {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyOwner {
        _safeTransfer(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override onlyOwner {
        _safeTransfer(from, to, tokenId, _data);
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        require(Counters.current(_tokenIdCounter) < _maxTotalSupply, "MosaicSquareVIP: It cannot be set to a value less than the existing value.");
        maxTotalSupply = _maxTotalSupply;
    }

    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "MosaicSquareVIP: New owner is the zero address");
        require(newOwner != owner, "MosaicSquareVIP: New owner is the same as the old owner");

        owner = newOwner;
    }
}