// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract CigarBoxNFT is ERC721A, Ownable, ReentrancyGuard {
    uint256 public constant MAX_MINTS = 1;
    uint256 public constant PRICE = 0.25 ether;
    uint256 public constant AMOUNT_FOR_RESERVE = 50;
    uint256 public constant COLLECTION_SIZE = 500;
    
    bool public isMintActive = false;
    string private _baseTokenURI;

    constructor() ERC721A("Society Cigars by Social House Cigar Club", "SOCIETYCIGAR") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function toggleMint() public onlyOwner {
        isMintActive = !isMintActive;
    }

    // for purchasing a cigar box
    function mintCigarBox(uint256 quantity) external payable callerIsUser {
        require(isMintActive, "Mint is not Active.");
        require(quantity * PRICE == msg.value, "Insuffient funds.");
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Exceeds collection size."
        );
        require(
            _numberMinted(msg.sender) + quantity <= MAX_MINTS,
            "Only one per wallet."
        );
        _safeMint(msg.sender, quantity);
    }

    // for giveaways 
    function mintReservedCigarBoxes(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "Can't mint this many. Check total supply."
        );
        require(
            _numberMinted(msg.sender) + quantity <= AMOUNT_FOR_RESERVE,
            "There are no more reserved mints."
        );
        _safeMint(msg.sender, quantity);
    }

    // metadata uri
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getCigarBoxOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    function burnCigarBox(uint256 tokenId) external onlyOwner nonReentrant {
        _burn(tokenId, true);
    }

    function withdrawFunds() public payable onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }
}
