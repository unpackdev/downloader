//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Abraka is ERC721A, Ownable {
    string public baseURI = "https://artnft.sgp1.digitaloceanspaces.com/abk/json/";
    bool public isPublicMintEnabled;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public maxTokensPerTx = 0;
    uint256 public maxFreeTokens = 0;

    constructor() ERC721A("Abraka", "ABK") {
        mintPrice = 0.2 ether;
        maxSupply = 630;
        isPublicMintEnabled = false;
    }

    function enablePublicMint() external onlyOwner {
        isPublicMintEnabled = true;
    }

    function disablePublicMint() external onlyOwner {
        isPublicMintEnabled = false;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    function setMaxTokensPerTx(uint256 maxTokens) public onlyOwner{
        maxTokensPerTx = maxTokens;
    }

    function setMaxFreeTokens(uint256 maxTokens) public onlyOwner{
        maxFreeTokens = maxTokens;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function mint(uint256 quantity) external payable {
        require(isPublicMintEnabled, "minting is not enabled");
        require(quantity > 0, "quantity must be greater than 0");
        require(maxTokensPerTx <= 0 || quantity <= maxTokensPerTx, "exceed max tokens per tx");
        require(totalSupply() + quantity <= maxSupply, "exceed max supply");

        uint256 price = 0;

        if (quantity > maxFreeTokens) {
            uint256 charged = quantity - maxFreeTokens;
            price = charged * mintPrice;
            maxFreeTokens = 0;
        } else {
            maxFreeTokens = maxFreeTokens - quantity;
        }

        require(price == msg.value, "ether value sent is not correct");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    } 

    function withdrawTo(address to, uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "exceed balance");
        payable(to).transfer(amount);
    } 

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory prefix = super.tokenURI(tokenId);
        return bytes(prefix).length != 0 ? string(abi.encodePacked(prefix, ".json")) : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}
