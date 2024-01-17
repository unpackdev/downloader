// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";

contract Altans is ERC721A, Ownable, Pausable, ReentrancyGuard {
    uint256 public cost = 0;   
    uint256 public maxSupply = 20;
    uint256 public maxMintAmount = 1;
    address private withdrawWallet;
    string baseURI;
    string public baseExtension;    

    constructor() ERC721A("AltansA", "A") {

        baseExtension = ".json";
        baseURI = "";
        withdrawWallet = address(msg.sender);
        _pause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function setMaxSupply(uint256 _newAmount) public onlyOwner {
        maxSupply = _newAmount;
    }

    function setMaxMintAmount(uint256 _newMax) public onlyOwner {
        maxMintAmount = _newMax;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWithdrawWallet(address wallet) public onlyOwner {
        withdrawWallet = wallet;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        (bool os, ) = payable(withdrawWallet).call{value: address(this).balance}("");
        require(os);
    }
    
   
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function adminMint(address to, uint256 _mintAmount) public onlyOwner {
        _mint(to, _mintAmount);
    }

    function mint(uint256 _mintAmount) external payable {
        if (msg.sender != owner()) {
            require(_mintAmount > 0, "Cannot mint less than zero Altans");
            require(_mintAmount <= maxMintAmount, "Cannot mint greater than 1 Altan");
            require(totalSupply() + _mintAmount <= maxSupply, "maximum supply exceeded");
            require(balanceOf(msg.sender) + _mintAmount <= maxMintAmount);

            _mint(msg.sender, _mintAmount);

        }else {
            _mint(msg.sender, _mintAmount);
        }
    }

    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal whenNotPaused virtual override(ERC721A) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }


    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(_baseURI(), _toString(tokenId), baseExtension)) : '';
    }
}