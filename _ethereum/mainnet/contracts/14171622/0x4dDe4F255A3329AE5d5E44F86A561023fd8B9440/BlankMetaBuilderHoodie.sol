//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./Ownable.sol";
import "./ERC721A.sol";

contract BlankMetaBuilderHoodie is ERC721A, Ownable {
    uint256 tokenPrice = 0.1 ether;
    uint256 maxSupply = 500;
    uint256 maxPerTx = 10;

    event PriceChanged(uint256 price);

    constructor() ERC721A("BlankMetaBuilderHoodie", "HOODIE", 10) {}

    function mint(uint256 amount) payable external {
        require(tx.origin == msg.sender, "The caller is another contract");
        require(amount <= maxPerTx, "No more than 10 per tx");
        require(msg.value >= amount * tokenPrice, "Not enough ether sent");
        require(totalSupply() + amount <= maxSupply, "No more hoodies left");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata to, uint256[] calldata amount) public onlyOwner {
        for(uint256 i = 0; i < to.length; i++) {
            require(totalSupply() + amount[i] <= maxSupply, "No more hoodies left");
            _safeMint(to[i], amount[i]);
        }
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        tokenPrice = _newPrice;
        emit PriceChanged(tokenPrice);
    }
    
    function withdrawFunds() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return "ipfs://QmVqodXFfpUU13GJDetcE2UtPLWMBsZubX6ZnhU3XDWhmJ";
    }
}