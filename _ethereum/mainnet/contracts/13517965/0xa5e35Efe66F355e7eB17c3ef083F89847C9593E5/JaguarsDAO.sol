// SPDX-License-Identifier: MIT

/*
 ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄         ▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄       ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄▄▄▄▄▄▄▄▄
▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░▌       ▐░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▌     ▐░░░░░░░░░░▌▐░░░░░░░░░░░▐░░░░░░░░░░░▌
 ▀▀▀▀▀█░█▀▀▀▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀▀▀▐░▌       ▐░▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀▀▀      ▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀▀▀▀█░▌
      ▐░▌   ▐░▌       ▐░▐░▌         ▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▐░▌               ▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▌
      ▐░▌   ▐░█▄▄▄▄▄▄▄█░▐░▌ ▄▄▄▄▄▄▄▄▐░▌       ▐░▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄▄▄      ▐░▌       ▐░▐░█▄▄▄▄▄▄▄█░▐░▌       ▐░▌
      ▐░▌   ▐░░░░░░░░░░░▐░▌▐░░░░░░░░▐░▌       ▐░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░░░░░░░░░░░▌     ▐░▌       ▐░▐░░░░░░░░░░░▐░▌       ▐░▌
      ▐░▌   ▐░█▀▀▀▀▀▀▀█░▐░▌ ▀▀▀▀▀▀█░▐░▌       ▐░▐░█▀▀▀▀▀▀▀█░▐░█▀▀▀▀█░█▀▀ ▀▀▀▀▀▀▀▀▀█░▌     ▐░▌       ▐░▐░█▀▀▀▀▀▀▀█░▐░▌       ▐░▌
      ▐░▌   ▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▐░▌     ▐░▌           ▐░▌     ▐░▌       ▐░▐░▌       ▐░▐░▌       ▐░▌
 ▄▄▄▄▄█░▌   ▐░▌       ▐░▐░█▄▄▄▄▄▄▄█░▐░█▄▄▄▄▄▄▄█░▐░▌       ▐░▐░▌      ▐░▌ ▄▄▄▄▄▄▄▄▄█░▌     ▐░█▄▄▄▄▄▄▄█░▐░▌       ▐░▐░█▄▄▄▄▄▄▄█░▌
▐░░░░░░░▌   ▐░▌       ▐░▐░░░░░░░░░░░▐░░░░░░░░░░░▐░▌       ▐░▐░▌       ▐░▐░░░░░░░░░░░▌     ▐░░░░░░░░░░▌▐░▌       ▐░▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀     ▀         ▀ ▀▀▀▀▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀▀ ▀         ▀ ▀         ▀ ▀▀▀▀▀▀▀▀▀▀▀       ▀▀▀▀▀▀▀▀▀▀  ▀         ▀ ▀▀▀▀▀▀▀▀▀▀▀
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract JaguarsDAO is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public hiddenURI;
    string public baseExtension = ".json";
    uint256 public PRICE = 0.1 ether;
    uint256 public MAX_SUPPLY = 10000;
    uint256 public AVAILABLE_FOR_PUBLIC = 9800;
    uint256 public MAX_MINT_AMOUNT = 5;
    bool public paused = false;
    bool public revealed = false;


    constructor() ERC721("Jaguars DAO", "JDAO") {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(!paused, "Sales Inactive");
        require(_mintAmount < 6, "Mint amount must be <= 5");
        require(supply + _mintAmount < 9801, "Mint amount exceeds the max supply available for public");
        require(msg.value >= PRICE * _mintAmount, "Value must be >= price * mint amount");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function devMint(uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= MAX_SUPPLY, "Mint amount exceeds the max supply");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }


    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return hiddenURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }


    function reveal() external onlyOwner() {
        revealed = !revealed;
    }

    function setCost(uint256 _newCost) external onlyOwner() {
        PRICE = _newCost;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner() {
        MAX_MINT_AMOUNT = _newMaxMintAmount;
    }

    function setHiddenURI(string memory _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    function withdraw() external payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}