// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC1155URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract EuterpeIPNFT is ERC1155URIStorage, Ownable, ReentrancyGuard {
    uint256 private _lastMintedId;
    string public name;
    string public symbol;
    mapping(address => bool) public minters;

    event BatchMint(address to, uint256[] amounts, uint256[] tokenIds);

    constructor(string memory name_, string memory symbol_) ERC1155(""){
        name = name_;
        symbol = symbol_;
        minters[msg.sender] = true;
    }

    function batchMint(address to, uint256[] memory amounts_, string[] calldata tokenURIs_) external nonReentrant {
        require(minters[msg.sender]);
        uint256[] memory tokenIds = new uint256[](amounts_.length);
        for (uint256 i = 0; i < amounts_.length; i++) {
            _mint(to, _lastMintedId, amounts_[i], "");
            _setURI(_lastMintedId, tokenURIs_[i]);
            tokenIds[i] = _lastMintedId;
            _lastMintedId++;
        }
        emit BatchMint(to, amounts_, tokenIds);
    }

    function mint (
        uint256 amount,
        string calldata tokenURI_
    ) external nonReentrant {
        require(minters[msg.sender]);
        _mint(msg.sender, _lastMintedId, amount, "");
        _setURI(_lastMintedId, tokenURI_);
        _lastMintedId++;
    }

    function setMinter(address account, bool isMinter) external onlyOwner {
        minters[account] = isMinter;
    }

    function setURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
        super._setURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        super._setBaseURI(baseURI);
    }
}

