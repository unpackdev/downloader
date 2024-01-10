//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract Phazuki is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY;
    string private BASE_URI;
    uint256 public MAX_MINT_AMOUNT_PER_WALLET;
    bool public IS_SALE_ACTIVE;

    constructor(
        uint256 maxSupply,
        string memory baseURI,
        uint256 maxMint
    ) ERC721A("Phazuki", "PHAZUKI", maxMint, maxSupply) {
        MAX_SUPPLY = maxSupply;
        BASE_URI = baseURI;
        MAX_MINT_AMOUNT_PER_WALLET = maxMint;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    ///////MINT FUNCTIONS///////

    function mintOwner(uint256 _mintAmount) external onlyOwner {
        require(totalSupply() + _mintAmount < MAX_SUPPLY, "Not enough NFTs");

        _safeMint(msg.sender, _mintAmount);
    }

    function mintNFTs(uint256 _mintAmount) external payable callerIsUser {
        require(IS_SALE_ACTIVE, "SALE IS NOT LIVE");
        require(totalSupply() + _mintAmount <= MAX_SUPPLY, "Not enough NFTs!");
        require(
            _mintAmount > 0 &&
                _mintAmount + numberMinted(msg.sender) <=
                MAX_MINT_AMOUNT_PER_WALLET,
            "Cannot mint specified number of NFTs."
        );

        require(
            msg.value >= GetPrice(_mintAmount) * _mintAmount,
            "Not enough ether to purchase NFTs."
        );

        _safeMint(msg.sender, _mintAmount);
    }

    ///////MISC FUNCTIONS///////

    function _baseURI() internal view virtual override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        BASE_URI = _baseTokenURI;
    }

    function Set_IS_SALE_ACTIVE(bool _active) external onlyOwner {
        IS_SALE_ACTIVE = _active;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function GetPrice(uint256 _mintAmount) internal view returns (uint256) {
        if (totalSupply() + _mintAmount <= 1000) {
            return 10000000000000000;
        } else if (
            (totalSupply() + _mintAmount) > 1000 &&
            (totalSupply() + _mintAmount) <= 2000
        ) {
            return 20000000000000000;
        } else if (
            (totalSupply() + _mintAmount) > 2000 &&
            (totalSupply() + _mintAmount) <= 3000
        ) {
            return 30000000000000000;
        } else if (
            (totalSupply() + _mintAmount) > 3000 &&
            (totalSupply() + _mintAmount) <= 4000
        ) {
            return 40000000000000000;
        } else {
            return 50000000000000000;
        }
    }

    //** PAYOUT **//

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
