// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";

contract BadCondom is ERC721A, Ownable {
    uint256 public MINT_PRICE = 0.05 ether;
    uint256 public MAX_SUPPLY = 299;
    uint256 public MAX_MINT_PER_ADDR = 5;
    string public baseURI = "https://badgirls.app/.netlify/functions/condom/";
    uint256 public mintedCount = 1;

    constructor(address[] memory addrs, uint[] memory amounts) ERC721A("Bad Condom", "BC") {
        _safeMint(msg.sender, 10);
        mintedCount += 10;

        // airdops
        for (uint i = 0; i < addrs.length; ++i) {
            _safeMint(addrs[i], amounts[i]);
            mintedCount += amounts[i];
        }
    }



    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function batchMint(uint256 amount) public payable {
        require(tx.origin == msg.sender, "No contract call");
        require(
            numberMinted(msg.sender) + amount <= MAX_MINT_PER_ADDR,
            "Exceeds the maximum mint amount of a single wallet"
        );
        require(mintedCount + amount <= MAX_SUPPLY, "Exceeded max mint range");

        uint256 totalPrice = MINT_PRICE * amount;
        require(msg.value >= totalPrice, "Insufficient eth");

        (bool sent, ) = owner().call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, amount);
        mintedCount += amount;
    }

    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == tx.origin, "Not the owner");
        _burn(tokenId);
    }
}
