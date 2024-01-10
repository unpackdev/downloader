// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ERC721A.sol";

contract PixelChads is ERC721A {
    address public immutable owner;

    uint64 public price = 0.02 ether;
    uint64 public count = 1000;
    uint64 maxPerTransaction = 20;

    constructor(address _owner) ERC721A("PixelChads", "PXC") {
        owner = _owner;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://Qmeq52cKnUYT2WdJMRWief8cuRLSjPCctgeFMS7XHbp7Jy/";
    }

    function mint(uint256 quantity) external payable {
        require(quantity <= maxPerTransaction, "Too many tokens requested!");
        require(quantity <= count, "Trying to mint more than available");
        require(msg.value >= price * quantity, "Paying less");

        payable(owner).transfer(msg.value);

        count -= uint64(quantity);
        _safeMint(msg.sender, quantity);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }
}