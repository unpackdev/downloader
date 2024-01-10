//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SoyVerse is Ownable, ERC721A, ReentrancyGuard {
    uint16 public constant COLLECTION_SIZE = 4200;
    uint16 public constant MAX_MINTS_DEV = 80;
    uint16 public constant MAX_MINTS_PER_ACCOUNT = 60;
    uint256 public constant MINT_PRICE = 0.03 ether;

    uint256 public mintStartTime;
    string private _baseTokenURI;

    constructor(uint256 mintStartTime_) ERC721A("SoyVerse", "SOY") {
        setMintStartTime(mintStartTime_);
    }

    function mint(uint256 quantity) external payable {
        require(isPublicSaleOn(), "public sale has not begun yet");
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINTS_PER_ACCOUNT,
            "can not mint this many"
        );
        require(
            msg.value == (MINT_PRICE * quantity),
            "Ether submitted does not match current price"
        );
        _safeMint(msg.sender, quantity);
    }

    // For marketing etc.
    function devMint(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "reached max supply"
        );
        require(
            numberMinted(msg.sender) + quantity <= MAX_MINTS_DEV,
            "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Withdraw ether from contract
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setMintStartTime(uint256 mintStartTime_) public onlyOwner {
        mintStartTime = mintStartTime_;
    }

    function isPublicSaleOn() public view returns (bool) {
        return mintStartTime <= block.timestamp;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
