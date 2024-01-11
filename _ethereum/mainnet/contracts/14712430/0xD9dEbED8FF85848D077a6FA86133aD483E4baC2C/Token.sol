// Top Frogs Genesis art is distributed under the CC0 license.
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

import "./ERC721A.sol";

contract Token is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable totalAmount;
    uint256 public constant AUCTION_PRICE = 0 ether;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 collectionSize_,
        uint256 totalAmount_
    ) ERC721A(name_, symbol_) {
        require(
            totalAmount_ <= collectionSize_,
            "the total amount must not be greater than the collection size"
        );
        _baseTokenURI = baseURI_;
        totalAmount = totalAmount_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "the caller is another contract");
        _;
    }

    function ownerMint(uint256 quantity) external payable onlyOwner {
        require(
            totalSupply() + quantity <= (totalSupply() > 0 ? totalSupply() : totalAmount),
            "not enough remaining"
        );
        mintQuantity(quantity);
    }

    function mintQuantity(uint256 quantity) private {
        uint256 totalCost = AUCTION_PRICE * quantity;
        _safeMint(msg.sender, quantity);
        refundIfOver(totalCost);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "need to send more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // Metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    string private _baseTokenURIExtension;

    function _baseURIExtension()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseTokenURIExtension;
    }

    function setBaseURIExtension(string calldata extension) external onlyOwner {
        _baseTokenURIExtension = extension;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "transfer failed");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function burnToken(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}