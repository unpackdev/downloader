// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract MadMaskGang is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;
    bool public saleIsActive = false;
    string private _baseURIextended;
    uint256 public constant MAX_MMGS = 10000;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public constant MMG_PRICE = 89E15; // 0.089 ETH

    constructor() ERC721("Mad Mask Gang", "MMG") {}

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

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_PURCHASE, "Exceeded max token purchase");
        require(
            totalSupply().add(numberOfTokens) <= MAX_MMGS,
            "Purchase would exceed max supply of tokens"
        );
        require(
            MMG_PRICE.mul(numberOfTokens) <= msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < 10000) {
                _safeMint(msg.sender, _tokenIdCounter.current());
                _tokenIdCounter.increment();
            }
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
