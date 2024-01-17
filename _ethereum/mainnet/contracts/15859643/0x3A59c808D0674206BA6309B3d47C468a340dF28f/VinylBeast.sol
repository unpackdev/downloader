// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

// # VinylBeast is an ONGOING Physital(Physical+Digital) Art Toy Project.
// # Only 5,000 Artistic NFTs, and each VinylBeast is very unique.
// # Let's be friends of VinylBeast and Walk Together. :)
// Web: vinylbeast.io | Twitter: @vinylbeast_io

contract VinylBeast is ERC721A, Ownable {
    uint256 public COLLECTION_SIZE;
    uint256 public MINT_AMOUNT;
    uint256 public MINT_PHASE_ONE;
    uint256 public MINT_PHASE_TWO;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    address payable public withdrawWallet;

    mapping(address => uint256) public walletMints;

    constructor() payable ERC721A('VinylBeast', 'VinylBeast') {
        COLLECTION_SIZE = 5000;
        MINT_AMOUNT = 4500;
        MINT_PHASE_ONE = 0.08 ether;
        MINT_PHASE_TWO = 0.15 ether;
        maxPerWallet = 5;
    }

    function setIsPublicMintEnable(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseTokenUri, _toString(tokenId), ".json"));
    }

    function __publicMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= COLLECTION_SIZE, "Not enough quantity");
        _safeMint(owner(), quantity);
    }

    function minPhaseOne(uint256 quantity) external payable {
        require(isPublicMintEnabled, "Minting(Phase One) is not active yet");
        require(msg.value == quantity * MINT_PHASE_ONE, "not enough ether");
        require(totalSupply() + quantity <= MINT_AMOUNT, "SOLD OUT!");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "exceed max wallet");
        walletMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function minPhaseTwo(uint256 quantity) external payable {
        require(isPublicMintEnabled, "Minting(Phase One) is not active yet");
        require(msg.value == quantity * MINT_PHASE_TWO, "not enough ether");
        require(totalSupply() + quantity <= MINT_AMOUNT, "SOLD OUT!");
        require(walletMints[msg.sender] + quantity <= maxPerWallet, "exceed max wallet");
        walletMints[msg.sender] += quantity;
        _safeMint(msg.sender, quantity);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }
}