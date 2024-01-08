// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Juicebois is ERC721Enumerable, Ownable {
    uint256 public constant MAX_NFT_SUPPLY = 5000;
    uint public constant MAX_PURCHASABLE = 30;
    uint256 public PRICE = 10**18 * 3/100; // 0.03 ETH

    bool public saleStarted = false;

    constructor() ERC721("Juicebois", "JUICE") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://api.juicebois.club/";
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function mint(uint256 amountToMint) public payable {
        require(saleStarted == true, "This sale has not started.");
        require(totalSupply() < MAX_NFT_SUPPLY, "All juices have been minted.");
        require(amountToMint > 0, "You must mint at least one juice.");
        require(amountToMint <= MAX_PURCHASABLE, "You cannot mint more than 30 juices.");
        require(totalSupply() + amountToMint <= MAX_NFT_SUPPLY, "The amount of juices you are trying to mint exceeds the maximum allowed count.");

        require(PRICE * amountToMint == msg.value, "Incorrect Ether value.");

        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function startSale() public onlyOwner {
        saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        saleStarted = false;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
