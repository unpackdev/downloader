// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.4; 

import "./ERC721.sol"; 
import "./Ownable.sol";

contract MIMINFT is ERC721, Ownable {
    uint256 public totalSupply; 
    uint256 public maxSupply; 
    uint256 public maxPerWallet; 
    bool public isMintEnabled; 
    string internal baseTokenUri; 
    address payable public withdrawWallet; 
    mapping(address => uint256) public walletMints; 

    constructor() payable ERC721('Mimies', 'MIMI') {
        totalSupply = 0; 
        maxSupply = 7777; 
        maxPerWallet = 1; 
        //set Royalties later
    }

    function setIsMintEnabled(bool isMintEnabled_) external onlyOwner{
        isMintEnabled = isMintEnabled_; 
    }

    function setBaseTokenURI(string calldata baseTokenUri_) external onlyOwner{
        baseTokenUri = baseTokenUri_; 
    }

    function setmaxPerWallet(uint256 quantity_) external onlyOwner {
        maxPerWallet = quantity_; 
    }

    function tokenURI(uint256 tokenID_) public view override returns (string memory) {
        require(_exists(tokenID_), 'Token does not exist'); 
        return string(abi.encodePacked(baseTokenUri, Strings.toString(tokenID_))); 
    } 

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawWallet.call{ value: address(this).balance }(''); 
        require(success, 'withdraw failed'); 
    }

    function mint(uint256 quantity_) public payable { 
        require(isMintEnabled, 'minting not enabled'); 
        require(totalSupply + quantity_ <= maxSupply, 'Mimies are all adopted'); 
        require(walletMints[msg.sender] + quantity_ <= maxPerWallet, 'exceed max wallet');

        for(uint256 i = 0; i < quantity_; i++) {
            uint256 newTokenId = totalSupply + 1; 
            totalSupply++; 
            _safeMint(msg.sender, newTokenId); //check affects interaction
        }
    }
}