// SPDX-License-Identifier: MIT
/**
  __  __                   _____              
 |  \/  |                 |  __ \             
 | \  / | ___   ___  _ __ | |__) |_ _ ___ ___ 
 | |\/| |/ _ \ / _ \| '_ \|  ___/ _` / __/ __|
 | |  | | (_) | (_) | | | | |  | (_| \__ \__ \
 |_|  |_|\___/ \___/|_| |_|_|   \__,_|___/___/                                             
                                         
*/


pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";

error HadClaimed();
error OutofMaxSupply();

contract MoonPass is ERC721A, Ownable {

    mapping(address => bool) public claimed;

    bool freeMintActive = false;

    uint256 public constant MAX_SUPPLY = 100;
    uint256 public cost = 0.05 ether;

    string public baseUrl = "ipfs://QmSUBuVDVHn3oWyWBb2z5hVpz6SwXHA9qPteUVk3BuX9fx";

    constructor() ERC721A("MoonPass", "MP") {}

    function freeMint() external {
        require(freeMintActive, "Free mint closed");
        if(totalSupply() + 1 > MAX_SUPPLY) revert OutofMaxSupply();
        if (claimed[msg.sender]) revert HadClaimed();
        claimed[msg.sender] = true;
        _safeMint(msg.sender, 1);
    }

    function revive() external payable {
        require(!freeMintActive, "Free mint is open");
        require(msg.value >= cost, "Insufficient funds");
        if(totalSupply() + 1 > MAX_SUPPLY) revert OutofMaxSupply();
        _safeMint(msg.sender, 1);
    }
    
    function ownerBatchMint(uint256 amount) external onlyOwner {
        if(totalSupply() + amount > MAX_SUPPLY) revert OutofMaxSupply();
        _safeMint(msg.sender, amount);
    }

    function batchBurn(uint256[] memory tokenids) external onlyOwner {
        uint256 len = tokenids.length;
        for (uint256 i; i < len; i++) {
            _burn(tokenids[i]);
        }
    }

    function toggleFreeMint(bool _state) external onlyOwner {
        freeMintActive = _state;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function setBaseURI(string memory url) external onlyOwner {
        baseUrl = url;
    }

    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        string memory currentBaseURI = _baseURI();
        return currentBaseURI;
    }

   function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }
}