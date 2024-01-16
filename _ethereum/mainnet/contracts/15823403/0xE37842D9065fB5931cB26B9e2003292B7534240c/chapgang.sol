// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract chapgang is ERC721A, Ownable {
    bool public pause = true;
    uint256 public cost = 0.008 ether;
    uint256 public totalsupply = 5555;
    string public baseURI = "ipfs:///";
    uint256 public constant maxWallet = 3;
    uint256 public constant maxFree = 1;

    constructor() ERC721A("Chap Gang", "CGToken") {
        _mint(msg.sender, 1);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "failed");
    }

    function setTokenUri(string calldata _baseTokenUri) public onlyOwner {
        baseURI = _baseTokenUri;
    }

    function toggleSales(bool val) external onlyOwner {
        pause = val;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI,_toString(tokenId),".json"));
    }

    function newPrice(uint256 p) external onlyOwner {
        cost = p;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function publicMint(uint256 quantity) external payable {
        require(!pause, "Paused!");
        require(quantity > 0 ,"Minimum Purchase is (1)");
        require(totalsupply >= _totalMinted() + quantity, "Chap Gang is sold out!");
        require(tx.origin == msg.sender, "Contract mint is not allowed");
        require(maxWallet >= _numberMinted(msg.sender) + quantity, "only 3 mints Per Wallet!");
        if(_numberMinted(msg.sender) < maxFree){
            require(msg.value >= (quantity - maxFree) * cost, "Insufficient funds");
        }else{
            require(msg.value >= quantity * cost, "Insufficient funds");
        }

        _mint(msg.sender, quantity);
    }
}