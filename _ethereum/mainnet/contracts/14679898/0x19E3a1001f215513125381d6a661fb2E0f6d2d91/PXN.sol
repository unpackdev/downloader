// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

/* 

    ██████  ██ ██   ██ ███████ ██          ███    ██ ███████ ██████  ██████  ███████     ███    ██ ███████ ████████ 
    ██   ██ ██  ██ ██  ██      ██          ████   ██ ██      ██   ██ ██   ██    ███      ████   ██ ██         ██    
    ██████  ██   ███   █████   ██          ██ ██  ██ █████   ██████  ██   ██   ███       ██ ██  ██ █████      ██    
    ██      ██  ██ ██  ██      ██          ██  ██ ██ ██      ██   ██ ██   ██  ███        ██  ██ ██ ██         ██    
    ██      ██ ██   ██ ███████ ███████     ██   ████ ███████ ██   ██ ██████  ███████     ██   ████ ██         ██    

    */

// Pixel Nerdz NFT - ERC-721A based NFT contract

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract PixelNerdzNFT is ERC721A, Pausable, Ownable, ReentrancyGuard {
    address private constant _creator =
        0x191726002b6AD80B386bC3fA001Cb9Df67a8999c;

    uint256 public MAX_SUPPLY = 4444;
    uint256 private MAX_MINTS_PER_TX = 20;

    bool private _locked = false;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.02 ether;

    string private _baseTokenURI;

    constructor() ERC721A("Pixel Nerdz NFT", "PXN") {}

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function mint(uint256 quantity) external payable nonReentrant onlyEOA {
        if (!isSaleActive()) revert("Sale not started");
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("Amount exceeds supply");
        if (getSalePrice() * quantity > msg.value)
            revert("Insufficient payment");
        if (quantity > MAX_MINTS_PER_TX)
            revert("Amount exceeds transaction limit");

        _safeMint(msg.sender, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > MAX_SUPPLY)
            revert("Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function setBaseURI(string calldata baseURI)
        external
        onlyOwner
        whenNotLocked
    {
        _baseTokenURI = baseURI;
    }

    function toggleSaleStatus() external onlyOwner whenNotLocked {
        _saleStatus = !_saleStatus;
    }

    // only downgrade
    function setMaxSupply(uint256 supply) external onlyOwner whenNotLocked {
        if (MAX_SUPPLY <= supply)
            revert("Requested supply shouldnt exceeds current max supply");
        if (totalSupply() >= supply)
            revert("Requested supply should exceeds current supply");
        MAX_SUPPLY = supply;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner whenNotLocked {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner whenNotLocked {
        _salePrice = price;
    }

    function lock() external onlyOwner {
        _locked = true;
    }

    function togglePause() external onlyOwner whenNotLocked {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function withdrawAll() external onlyOwner {
        withdraw(_creator, address(this).balance);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    modifier onlyEOA() {
        if (tx.origin != msg.sender)
            revert("Only externally owned accounts allowed");
        _;
    }

    modifier whenNotLocked() {
        require(!_locked, "Locked");
        _;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {}
}
