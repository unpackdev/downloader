// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract RealArt is ERC721URIStorage, Ownable, ReentrancyGuard {

    uint256 private totalSupply = 0;
    uint256 public constant MAXSUPPLY = 10000;
    uint256 public constant MINTPRICE = 69000000000000000;

    bool public active = false;
    string public baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) ERC721(name, symbol) {
        baseTokenURI = baseURI;
    }

    function mint(
        uint256 _tokenID,
        string memory _tokenURI
    ) public payable {
        require(active, "Mint not activated");
        require(totalSupply + 1 <= MAXSUPPLY, "Maximum supply exceeded");
        require(MINTPRICE <= msg.value, "Insufficient ether");
        totalSupply += 1;

        _safeMint(msg.sender, _tokenID);
        _setTokenURI(_tokenID, _tokenURI);
    }

    function mintedSupply() public view returns (uint256) {
        return totalSupply;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function activate() public onlyOwner {
        active = !active;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

}