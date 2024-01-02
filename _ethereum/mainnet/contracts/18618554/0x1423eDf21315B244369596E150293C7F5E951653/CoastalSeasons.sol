// SPDX-License-Identifier: MIT

// COASTAL SEASONS A.I. 

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract CoastalSeasons is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public maxSupply = 221;
    uint256 public cost = 0.012 ether;
    uint256 public maxPerWallet = 3;
    uint256 public maxMintAmountPerTx = 3;
    string public baseURI;
    bool public paused = true;
    bool public publicMintOpen = false;
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721A(_tokenName, _tokenSymbol) {}

    modifier mintCompliance(uint256 quantity) {
        require(quantity > 0 && quantity <= maxMintAmountPerTx, "Invalid mint amount!");
        require(_numberMinted(msg.sender) + quantity <= maxPerWallet, "Max per wallet mint exceeded");
        require(totalSupply() + quantity < maxSupply + 1, "Max supply exceeded");
        _;
    }

    modifier mintPriceCompliance(uint256 quantity) {
        uint256 realCost = 0;
        require(msg.value >= cost * quantity - realCost, "Please send the exact amount.");
        _;
    }

    function editMintWindows(
        bool _publicMintOpen
    ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
    }

    function publicMint(uint256 quantity) public payable mintCompliance(quantity) mintPriceCompliance(quantity) {
        require(publicMintOpen, "Public closed!");
        require(msg.value >= 0.012 ether, "Incorrect Value!");
        _safeMint(msg.sender, quantity);
    }

    function ownerMint(uint256 quantity)
        public
        payable
        mintCompliance(quantity)
        onlyOwner
    {
        _safeMint(_msgSender(), quantity);
    }

    function mintBatch(address[] memory recipients) public onlyOwner {
    uint256 length = recipients.length;
    require(length > 0, "Empty recipient array");

    for (uint256 i = 0; i < length; i++) {
        _safeMint(recipients[i], 1);
    }
    }


    function reserveTokens(uint256 numTokens) external onlyOwner {
    require(totalSupply() + numTokens <= maxSupply, "Exceeds maximum supply");
    maxSupply -= numTokens;
    }



    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }


    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}