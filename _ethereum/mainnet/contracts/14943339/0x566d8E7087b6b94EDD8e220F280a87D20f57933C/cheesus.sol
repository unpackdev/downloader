// SPDX-Licnese-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract CheesusNFT is ERC721, Ownable {

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;

    bool public isPublicMintEnabled;
    bool public revealed = false;
    mapping(address => uint256) public walletMints;

    string internal baseTokenUri;
    string public hiddenMetadataUri;

    constructor() payable ERC721('CheesusNFT', 'CHEESUS') {
        mintPrice = 0.01 ether;
        totalSupply = 0;
        maxSupply = 5000;
        maxPerWallet = 20;
        setHiddenMetadataUri("ipfs://QmbopepqoEycZfcfx7GVQEBvVKNrAS5CZyftiHkWQPGLsV/0.json");
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled =  isPublicMintEnabled_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist!');
        
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ".json"));
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, 'withdraw failed');
    }

    function mint(uint256 quantity_) public payable {
        require(isPublicMintEnabled, 'minting not enabled');
        require(msg.value == quantity_ * mintPrice, 'wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'sold out');
        require(walletMints[msg.sender] + quantity_ < maxPerWallet, 'exceed max wallet');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}

