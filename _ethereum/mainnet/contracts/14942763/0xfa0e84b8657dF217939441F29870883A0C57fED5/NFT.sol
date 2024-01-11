// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721.sol";
import "Ownable.sol";
import "ERC721Enumerable.sol";

contract NFT is ERC721, ERC721Enumerable, Ownable {
    bool public saleIsActive = false;
    string private _baseURIextended;

    uint256 public MAX_SUPPLY;
    uint256 public currentPrice;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 price,
        uint256 maxSupply
    ) ERC721(_name, _symbol) {
        currentPrice = price;
        MAX_SUPPLY = maxSupply;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function reserve(uint256 n) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 i;
        for (i = 0; i < n; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function setSaleIsActive(bool isActive) public onlyOwner {
        saleIsActive = isActive;
    }

    function setCurrentPrice(uint256 price) public onlyOwner {
        currentPrice = price;
    }

    function mint(uint256 numberOfTokens) public payable {
        uint256 ts = totalSupply();
        require(saleIsActive, "Sale must be active to mint tokens");
        require(
            ts + numberOfTokens <= MAX_SUPPLY,
            "Purchase would exceed max tokens"
        );
        require(
            currentPrice * numberOfTokens <= msg.value,
            "Value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, ts + i);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
