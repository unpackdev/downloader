// SPDX-License-Identifier: MIT

/**

███╗   ███╗███████╗███████╗██████╗ ███████╗██╗     ███████╗███████╗███████╗
████╗ ████║██╔════╝██╔════╝██╔══██╗██╔════╝██║     ██╔════╝██╔════╝██╔════╝
██╔████╔██║█████╗  █████╗  ██████╔╝███████╗██║     █████╗  ███████╗███████╗
██║╚██╔╝██║██╔══╝  ██╔══╝  ██╔══██╗╚════██║██║     ██╔══╝  ╚════██║╚════██║
██║ ╚═╝ ██║██║     ███████╗██║  ██║███████║███████╗███████╗███████║███████║
╚═╝     ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝╚══════╝

**/

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

/**
 * @title MfersLess contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MfersLess is ERC721Enumerable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using Strings for uint256;

    // Vars ----------------------

    uint256 public constant MAX_SUPPLY = 10000;

    bool public saleActive = true;
    uint256 public price = 0.015 ether;

    bool public revealed = false;

    // Base URI ----------------------

    string private baseURI;
    string public notRevealedUri;

    // Events ----------------------

    event Mint(address recipient, uint256 tokenId);
    event Gift(address recipient, uint256 numberOfMints);

    // Init ----------------------

    constructor(string memory _initNotRevealedUri) ERC721("MfersLess", "MFRS") {
        setNotRevealedURI(_initNotRevealedUri);
    }

    // Mint ----------------------
    function mint(uint256 numberOfMints) public payable nonReentrant {
        uint256 supply = totalSupply();

        require(saleActive, "Sale must be active to mint");
        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");
        require(price.mul(numberOfMints) == msg.value, "Ether value sent is not correct");
        require(msg.value >= price * numberOfMints, "Insufficient balance to mint");

        if (supply + numberOfMints >= MAX_SUPPLY) {
            saleActive = !saleActive;
        }

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Mint(msg.sender, tokenId);
            _safeMint(msg.sender, tokenId);
        }
    }

    function gift(address recipient, uint256 numberOfMints) external onlyOwner nonReentrant {
        uint256 supply = totalSupply();

        require(numberOfMints > 0, "The minimum number of mints is 1");
        require(supply.add(numberOfMints) <= MAX_SUPPLY, "Further minting would exceed max supply");

        for (uint256 i; i < numberOfMints; i++) {
            uint256 tokenId = supply + i;
            emit Gift(recipient, tokenId);
            _safeMint(recipient, tokenId);
        }
    }

    // Setters ----------------------

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }

    function isSaleFinished() private view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function baseTokenURI() public view returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Funcs ----------------------

    function walletOfOwner(address owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawGroup(address[] memory addresses) external onlyOwner {
        uint256 balance = address(this).balance / addresses.length;

        for(uint256 i; i < addresses.length; i++){
            payable(addresses[i]).transfer(balance);
        }
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
        bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
    }
}