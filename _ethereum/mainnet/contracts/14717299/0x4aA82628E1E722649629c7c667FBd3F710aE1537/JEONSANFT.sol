// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";

contract JEONSANFT is ERC721, Ownable {

    //Variables

    uint256 public mintPrice;
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public maxPerWallet;
    bool public isPublicMintEnabled;
    string internal baseTokenUri;
    address public withdrawWallet;
    mapping(address => uint256) public walletMints;

    constructor() payable ERC721('JEONSA', 'JEONFT'){
        mintPrice = 0.2 ether;
        totalSupply = 0;
        maxSupply = 10000;
        maxPerWallet = 5;
        withdrawWallet = owner();
    }

    function setIsPublicMintEnabled(bool isPublicMintEnabled_) external onlyOwner {
        isPublicMintEnabled = isPublicMintEnabled_;
    }

    function setBaseTokenUri(string calldata baseTokenUri_) external onlyOwner {
        baseTokenUri = baseTokenUri_;
    }

    function setMaxSupply(uint256 maxSupply_ ) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function tokenURI(uint tokenId_) public view override returns (string memory) {
        require(_exists(tokenId_), 'Token does not exist!');
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenId_), ""));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }('');
        require(success, 'withdraw failed');
    }

    function mint(uint quantity_) public payable {
        require(isPublicMintEnabled, 'Minting is not enabled');
        require(msg.value == quantity_ * mintPrice, 'Wrong mint value');
        require(totalSupply + quantity_ <= maxSupply, 'Sold Out');
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'Exceeded max mints per wallet');

        for (uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1;
            totalSupply ++;
            _safeMint(msg.sender, newTokenId);
        }
    }
}
