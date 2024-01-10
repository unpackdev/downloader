// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SpaceBabes is Ownable, ERC721A, ReentrancyGuard {

    uint256 public immutable collectionSize;
    address withdrawWallet = 0x3a86FD7949F1bD3b2Bfb8dA3f5e86cFEDC79e0Fb;

    constructor(
        uint256 collectionSize_
    ) ERC721A("SpaceBabes", "SB", collectionSize_) {
        collectionSize = collectionSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function bulkMintMap(address[] memory who, uint256[] memory quantityList) public onlyOwner {
        for (uint256 i = 0; i < who.length; i++) internalMint(who[i], quantityList[i]);
    }

    function internalMint(address to, uint256 quantity) internal virtual {
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        _safeMint(to, quantity);
    }

    // // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(withdrawWallet).transfer(balance);
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }
}
