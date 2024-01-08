// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract SportsIconLionClub is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable
{
    using SafeMath for uint256;

    // Lion price 0.08 ETH
    uint256 public constant lionPrice = 80000000000000000;

    uint256 public constant maxPurchase = 10;

    uint256 public constant maxLions = 8000;

    // Reserve max 185 tokens for founding NFT owners and team
    uint256 public reserve = 185;

    bool public saleIsActive = false;

    string private baseURI;

    constructor() ERC721("SportsIcon Lion Club", "SLC") {}

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function mintLion(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Lions");
        require(
            numberOfTokens > 0 && numberOfTokens <= maxPurchase,
            "Can only mint 10 Lions at a time"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxLions,
            "Purchase would exceed max supply of Lions"
        );
        require(
            msg.value >= lionPrice.mul(numberOfTokens),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();

            if (mintIndex < maxLions) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function reserveLions(address to, uint256 numberOfTokens) public onlyOwner {
        uint256 supply = totalSupply();

        require(
            numberOfTokens > 0 && numberOfTokens <= reserve,
            "Not enough reserve left"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(to, supply + i);
        }

        reserve = reserve.sub(numberOfTokens);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
