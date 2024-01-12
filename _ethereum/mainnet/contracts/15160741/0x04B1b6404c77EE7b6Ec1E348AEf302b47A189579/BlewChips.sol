// SPDX-License-Identifier: MIT

/*
 _     _                      _     _
| |__ | | _____      __   ___| |__ (_)_ __ ____
| '_ \| |/ _ \ \ /\ / /  / __| '_ \| | '_ \_  /
| |_) | |  __/\ V  V /  | (__| | | | | |_) / /
|_.__/|_|\___| \_/\_/    \___|_| |_|_| .__/___|
                                     |_|
*/

pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract BlewChipz is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {

    string private baseTokenURI;
    bool public saleStarted = false;
    uint256 public maxSupply = 5000;
    uint256 public maxMints = 5;

    // track mints per user
    mapping(address => uint256) public mintMeta;

    constructor() ERC721("BlewChipz", "BLEW") {
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function stopSale() public onlyOwner {
        saleStarted = false;
    }

    // ability to lower the number of mints in case failure to mint out.
    function decreaseMaxSupply(uint256 _maxSupply) public onlyOwner {
        require(totalSupply() <= _maxSupply, "Current supply exceeds selected max supply");
        require(_maxSupply <= maxSupply, "Amount can only be decremented");
        maxSupply = _maxSupply;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return baseTokenURI;
    }

    function mint(uint256 _amount) public nonReentrant {
        uint256 mintedBlewChips = totalSupply();

        require(saleStarted, "sale not yet started");
        require(mintedBlewChips + _amount <= maxSupply, "mint sold out");
        require((mintMeta[msg.sender] + _amount) <= maxMints, "mint limit reached");

        for (uint i = 0; i < _amount; ++i) {
            uint256 tokenId = totalSupply();
            mintMeta[msg.sender] ++;
            _safeMint(msg.sender, tokenId);
        }
    }

    // update maxMints after certain time has passed to allow people more than preset max
    function increaseMaxMints(uint256 _maxMints) public onlyOwner {
        maxMints = _maxMints;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
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
}
