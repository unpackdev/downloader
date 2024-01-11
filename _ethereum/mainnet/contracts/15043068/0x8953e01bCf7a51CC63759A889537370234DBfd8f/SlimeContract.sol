// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract SlimeContract is ERC721, Ownable {
    bool public isMintEnabled;
    string internal baseTokenUri;
    uint256 public mintPrice;
    uint256 public maxSupply;
    uint256 public totalSupply;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721('Slime Token', 'SLM') {
        mintPrice = 0.15 ether;
        maxSupply = 100;
        baseTokenUri = "ipfs://QmYA96Pqu5nPUcfPXehwN736X2b5wKcqEyFLz9GrDkBtat/";
        totalSupply = 0;
        isMintEnabled = false;
    }

    function toggleIsMintEnabled() external onlyOwner {
        isMintEnabled = !isMintEnabled;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI (uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function withdraw() external onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function ownerMint(uint256 quantity_) external payable onlyOwner {
        for (uint256 i = 0; i < quantity_; i++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }

    function mint(uint256 quantity_) public payable {
        require(isMintEnabled, 'minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'wrong value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(walletMints[msg.sender] + quantity_ <= 1, 'exedeed max per wallet');

        for (uint256 i = 0; i < quantity_; i++){
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}