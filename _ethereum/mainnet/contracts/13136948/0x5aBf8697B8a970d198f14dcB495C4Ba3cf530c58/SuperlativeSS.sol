// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract SuperlativeSS is Ownable, ERC721Enumerable {
    using Strings for uint256;
    
    uint256 public constant PRICE = 0.079 ether;

    uint256 public constant TOTAL_TOKEN = 11111;

    uint256 public constant MAX_PURCHASE = 21;

    bool public saleIsActive = false;

    string private _contractURI = "";
    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active");
        require(
            numberOfTokens > 0 && numberOfTokens <= MAX_PURCHASE,
            "Can only mint 21 tokens at a time"
        );
        require(
            totalSupply() + numberOfTokens <= TOTAL_TOKEN,
            "Purchase would exceed max supply of token"
        );
        require(
            msg.value >= PRICE * numberOfTokens,
            "ETH amount is not sufficient"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < TOTAL_TOKEN) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function gift(address _to, uint256 _amount) public onlyOwner {
        require(
            totalSupply() + _amount <= TOTAL_TOKEN,
            "This transaction would exceed max supply of token"
        );
        for (uint256 i = 0; i < _amount; i++) {
            uint256 mintIndex = totalSupply();
            if (mintIndex < TOTAL_TOKEN) {
                _safeMint(_to, mintIndex);
            }
        }
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        onlyOwner
    {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        return
            bytes(revealedBaseURI).length > 0
                ? string(abi.encodePacked(revealedBaseURI, tokenId.toString()))
                : _tokenBaseURI;
    }
}
