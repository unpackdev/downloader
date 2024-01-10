// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ElonaMusk is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5420;

    bool public saleActive = false;
    uint256 public price = 0.02420 ether;
    uint256 public maxPerTx = 20;
    uint256 public maxPerAddress = 50;

    constructor() ERC721A("Elona Musk", "ELONAS") {}

    function startSale() public onlyOwner {
        saleActive = true;
    }

    function stopSale() public onlyOwner {
        saleActive = false;
    }

    function setMaxPerTx(uint256 _maxPerTx) external onlyOwner {
        maxPerTx = _maxPerTx;
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
        maxPerAddress = _maxPerAddress;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    // metadata URI
    string private _baseTokenURI;

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), '.json')) : '';
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function reserve(uint256 quantity) external onlyOwner {
        require((totalSupply() + quantity) <= MAX_SUPPLY, "Exceed max supply.");
        _safeMint(msg.sender, quantity);
    }

    function mint(uint256 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Exceed max supply.");
        require(saleActive, "Mint is not active.");
        require((price * quantity) <= msg.value, "Not enough amount sent.");
        require(numberMinted(msg.sender) + quantity <= maxPerAddress, "Too many per wallet.");
        require(quantity <= maxPerTx, "Too many per transaction.");

        _safeMint(msg.sender, quantity);
    }
}