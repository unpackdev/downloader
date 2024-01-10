//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";


contract MfersNFT is ERC721A, Ownable {

    uint public MINT_PRICE = 0.05 ether;
    uint public MAX_SUPPLY = 10000;
    uint public MAX_MINT_PER_ADDR = 10;
    string public baseURI = 'https://mfers-in-wallstreet.netlify.app/.netlify/functions/meta/';
    uint256 public mintedCount = 0;


    constructor() ERC721A("Mfers In Wallstreet", "MFIW") {
        _safeMint(msg.sender, 1);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function batchMint(uint amount) public payable {
        require( amount <= MAX_MINT_PER_ADDR, "Exceeds the maximum mint amount of a single transaction");
        require( mintedCount + amount <= MAX_SUPPLY, "Exceeded max mint range");
        uint totalPrice = MINT_PRICE * amount;
        require(msg.value >= totalPrice, "Insufficient eth");

        (bool sent,) = owner().call{value: msg.value - totalPrice * 4 / 5 }("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, amount);
        mintedCount += amount;
    }

    function random() private view returns (uint) {
        uint big = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return big % mintedCount;
    }

    function shuffle() public onlyOwner {
        for (uint i = 0; i < 400; ++i) {
            address luck = ownerOf(random());
            (bool sent,) = luck.call{value: address(this).balance / 400}("");
            if (!sent) {
                --i;
            }
        }
    }
}