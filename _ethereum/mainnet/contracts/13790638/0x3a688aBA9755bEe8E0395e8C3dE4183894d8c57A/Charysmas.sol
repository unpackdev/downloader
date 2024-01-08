// SPDX-License-Identifier: MIT

/**

█▀▀ █░█ ▄▀█ █▀█ █▄█ █▀ █▀▄▀█ ▄▀█ █▀
█▄▄ █▀█ █▀█ █▀▄ ░█░ ▄█ █░▀░█ █▀█ ▄█

**/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Charysmas contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Charysmas is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Minting
    bool public saleActive = true;
    uint256 public maxMintPerTransaction = 10;
    uint256 public price = 0.05 ether;
    uint256 public constant MAX_SUPPLY = 4022;

    // Base URI
    string private baseURI;

    event Mint(address recipient, uint256 tokenId);

    constructor() ERC721("Charysmas", "CHS") {
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    // @dev Dynamically set the max mints a user can do in the main sale
    function setMaxMintPerTransaction(uint256 maxMint) external onlyOwner {
        maxMintPerTransaction = maxMint;
    }

    function mint(uint256 numberOfMints) public payable nonReentrant {
        uint256 supply = totalSupply();

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints <= maxMintPerTransaction, "Amount exceeds mintable limit");
        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(price.mul(numberOfMints) == msg.value, "Ether value sent is not correct");
        require(address(this).balance >= msg.value, "Insufficient balance to mint");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(msg.sender, tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    // @dev Check if sale has been sold out
    function isSaleFinished() private view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }

    // @dev List tokens per owner
    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // @dev Private mint function reserved for company.
    function ownerMintToAddress(address recipient, uint256 numberOfMints) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();

        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(recipient, tokenId);
            _safeMint(recipient, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}