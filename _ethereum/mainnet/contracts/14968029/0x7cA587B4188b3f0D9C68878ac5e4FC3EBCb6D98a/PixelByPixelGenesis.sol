//SPDX-License-Identifier: MIT

// This Contract is Deployed and Controlled by Pixel by Pixel Studios Inc.

pragma solidity ^0.8.4;

import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract PixelByPixelGenesis is Ownable, ERC721A, IERC2981, ReentrancyGuard {
    
    string private _baseTokenURI;

    uint256 public constant collectionSize = 1000;

    // ======== Mint Variables ========
    bool public isMintActive = false;
    uint256 public maxMint = 1;
    uint256 public publicSale = 0.1 ether;

    // ======== Royalty Variables =========
    address public royaltyAddress;
    uint256 public royaltyPercent;

    constructor() ERC721A("Pixel by Pixel Studios Genesis", "PBP") {
        royaltyAddress = owner();
        royaltyPercent = 5;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMintActive(bool mintState) public onlyOwner {
        isMintActive = mintState;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMintPrice(uint256 weiPrice) external onlyOwner {
        publicSale = weiPrice;
    }

    function setMaxMint(uint256 max) external onlyOwner {
        maxMint = max;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

    function mint(uint256 quantity) external callerIsUser {
        require(isMintActive, "minting has not begun yet");
        require(totalSupply() + quantity <= collectionSize, "reached max supply");
        require(quantity <= maxMint, "quantity is greater than max mint");

        _safeMint(msg.sender, quantity);
    }

    function mintToAddress(address[] memory addresses) external onlyOwner {
        require(totalSupply() + addresses.length <= collectionSize, "reached max supply.");

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], 1);
        }
    }

    // ======== Royalties =========
    function setRoyaltyReceiver(address royaltyReceiver) public onlyOwner {
        require(royaltyReceiver != address(0), "Royalties: new recipient is the zero address");
        royaltyAddress = royaltyReceiver;
    }

    function setRoyaltyPercentage(uint256 royaltyPercentage) public onlyOwner {
        royaltyPercent = royaltyPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId), "Non-existent token");
        return (royaltyAddress, salePrice * royaltyPercent / 100);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
