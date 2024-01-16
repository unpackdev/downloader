// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

interface IAristocratContract {
    function ownerOf(uint256 index)
        external
        returns (address);
}

contract GTVNUC is Ownable, ReentrancyGuard, ERC721A {
    uint256 public immutable maxMint;
    uint256 public aristocratSupply = 3000;
    IAristocratContract private aristocratSC =
        IAristocratContract(0x13e1c9123DdE5334E8c2B24DB9F2Dc16f5673DE6);
    uint256 public mainSupply = 7777;
    uint256 public publicSupply = mainSupply - aristocratSupply;
    uint256 public mainPrice = 0.027 ether;
    string private _baseTokenURI;
    bool public mintLive = false;

    mapping(uint256 => bool) public isMinted;

    constructor(uint256 maxMint_, string memory baseTokenURI_)
        ERC721A("GTVNUC", "GTVNUC", maxMint_)
    {
        maxMint = maxMint_;
        _baseTokenURI = baseTokenURI_;
    }

    modifier publicRules(uint256 _mintCount) {
        require(_mintCount > 0, "Invalid mint amount!");
        require(publicSupply > 0, "Sold Out");
        require(publicSupply - _mintCount >= 0, "Max supply exceeded!");
        require(msg.value >= mainPrice * _mintCount, "Insufficient funds!");
        _;
    }

    function publicMint(uint256 _mintCount)
        external
        payable
        publicRules(_mintCount)
    {
        require(mintLive, "Mint is not open yet");
        publicSupply -= _mintCount;
        _safeMint(msg.sender, _mintCount);
    }

    function aristocratMint(uint256 _tokenId) external {
        require(mintLive, "Mint is not open yet");
        require(msg.sender == aristocratSC.ownerOf(_tokenId), "Ring is not yours!");
        require(aristocratSupply > 0, "Sold Out");
        require(aristocratSupply - 1 >= 0, "You need to have at least 1 ring available to claim");
        require(!isMinted[_tokenId], "This ring already claimed");
        isMinted[_tokenId] = true;
        aristocratSupply -= 1;
        _safeMint(msg.sender, 1);
    }

    function setMintPrice(uint256 _mainPrice) external onlyOwner {
        mainPrice = _mainPrice;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function toggleSale() external onlyOwner {
        mintLive = !mintLive;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
