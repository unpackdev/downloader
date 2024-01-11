// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC2981.sol";

contract GuyFawkesBloc is
    ERC721A,
    Ownable,
    ReentrancyGuard,
    IERC2981
{
    // attributes
    uint256 immutable public collectionSize = 8888;
    uint256 constant public publicPrice = 0.04 ether;

    bool public isPublicActive = false;

    string private baseURI;

    constructor(
        string memory name,
        string memory symbol
    )
        ERC721A(name, symbol) {}

    // modifiers
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setPublicActive() public onlyOwner {
        isPublicActive = !isPublicActive;
    }

    function ownerMint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    function publicSaleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        require(isPublicActive, "public sale has not begun yet");
        require(
            totalSupply() + quantity <= collectionSize,
            "reached max supply"
        );
        _safeMint(msg.sender, quantity);
        refundIfOver(publicPrice * quantity);
    }

    // Private
    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    // IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice / 100) * 10;
        return (address(this), royaltyAmount);
    }
}
