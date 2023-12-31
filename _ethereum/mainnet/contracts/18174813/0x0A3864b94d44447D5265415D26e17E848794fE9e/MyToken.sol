// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

contract CATTOS is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint public constant MAX_TOKENS = 1000;
    uint private constant TOKENS_RESERVED = 1;
    uint public price = 1000000000000000;
    uint256 public constant MAX_MINT_PER_TX = 10;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => bool) public FreeClaimed;
   
    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("CATTOS", "CTS") {
        baseUri = "ipfs://bafybeiehmqqlcaen35rvjc7nmvb5gwnlmgjwirlpgtsu3bqkhsdyxqag7y/";
        for(uint256 i = 1; i <= TOKENS_RESERVED; ++i) {
            _safeMint(msg.sender, i);
        }
        totalSupply = TOKENS_RESERVED;
    }

    // Public Functions
    function mint(uint256 tokens) public payable nonReentrant {
        require(isSaleActive, "The sale is paused.");
        require(tokens <= MAX_MINT_PER_TX, "You cannot mint that many in one transaction.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + tokens <= MAX_TOKENS, "Exceeds total supply.");

        if (!FreeClaimed[msg.sender]) {
            uint256 pricetopay = tokens - 1;
            require(msg.value >= price * pricetopay, "Insufficient funds.");
            FreeClaimed[msg.sender] = true;
        } else {
            require(msg.value >= price * tokens, "Insufficient funds.");
        }

        for(uint256 i = 1; i <= tokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        totalSupply += tokens;
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }


function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    (bool transferSuccess, ) = payable(owner()).call{value: balance}("");
    require(transferSuccess, "Transfer failed.");
}


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
