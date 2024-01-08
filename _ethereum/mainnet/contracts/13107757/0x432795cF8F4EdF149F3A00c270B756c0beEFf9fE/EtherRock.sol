// contracts/EtherRock.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";

contract EtherRock is ERC721Enumerable, Ownable {

    using SafeMath for uint;

    string internal baseURI;

    mapping(uint => bool) private forSale;
    mapping(uint => uint) private price;
    mapping(uint => uint) private timesSold;

    constructor(address owner, string memory tokenBaseUri) ERC721("EtherRock", "ROCK") {
        Ownable.transferOwnership(owner);
        baseURI = tokenBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function getRock (uint tokenId) public view returns (address, bool, uint, uint) {
        require(tokenId < 100, "ERC721: operator getRock for nonexistent token");
        if(_exists(tokenId)){
            return (ERC721.ownerOf(tokenId), forSale[tokenId], price[tokenId], timesSold[tokenId]);
        }else{
            return (address(this), true, _getMintPrice(), 0);
        }
    }

    function _getMintPrice() internal view virtual returns (uint) {
        uint total=totalSupply();
        return total.mul(total).mul(0.001 ether).add(0.001 ether);
    }

    function buyRock (uint tokenId) public payable {
        require(tokenId < 100, "ERC721: operator buyRock for nonexistent token");
        if (_exists(tokenId)) {
            require(msg.value == price[tokenId], "Incorrect price");
            require(forSale[tokenId] == true, "This rock is not for sale");
            payable(ERC721.ownerOf(tokenId)).transfer(price[tokenId]);
            _transfer(ERC721.ownerOf(tokenId),msg.sender,tokenId);
        }else{
            uint mintPrice = _getMintPrice();
            require(tokenId == totalSupply(), "Incorrect rock Id");
            require(msg.value == mintPrice, "Incorrect price");
            payable(owner()).transfer(mintPrice);
            _safeMint(msg.sender, tokenId);
        }
        forSale[tokenId] = false;
        timesSold[tokenId]++;
    }

    function sellRock (uint tokenId, uint price_) public {
        require(msg.sender == ERC721.ownerOf(tokenId), "You don't own this rock");
        require(price_ > 0, "Please name a price");
        forSale[tokenId] = true;
        price[tokenId] = price_;
    }

    function dontSellRock (uint tokenId) public {
        require(msg.sender == ERC721.ownerOf(tokenId), "You don't own this rock");
        forSale[tokenId] = false;
    }

    function rocksOfOwner(address owner) public view returns(uint[] memory) {
        uint length = ERC721.balanceOf(owner);
        uint[] memory rockIds = new uint[](length);
        for(uint i = 0; i < length; i++){
            rockIds[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
        return rockIds;
    }
}