// SPDX-License-Identifier: MIT

/*
                                                                                    
                                                                                
                      .....                          .....                      
                   .lkKXKd'                          ,xKXKkl.                   
                  cKMMMWd.                            .xWMMWK:                  
                 cXMMMMK,        ..          ..        ;KMMMMK,                 
                .xMMMMMK,       .do.        .xo.       ;XMMMMWo                 
                .xMMMMMNo       ;KNc       .dWK,      .xWMMMMWo                 
                 :XMMMMMXl.   .cKMWx.      .kMMKc.   'xNMMMMM0,                 
                  ;OWMMMMWKkdxKWMWO,        ;0WMWKxdkXMMMMWKd'                  
                   .:x0XNNNNNXK0xc.          .:dOKXXXXK0ko;.                    
                       ..''''...                 ......                         


                                    LOOK AWAY

                      CHAPTER ONE: THE EYES OF THE MONARCHS





                                  lookaway.xyz
*/

pragma solidity ^0.8.17;

import "./MerkleProof.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./SafeMath.sol";

abstract contract DesintationBurnContractI {
    function mintTransfer(address to) public virtual returns(uint256);
}

contract LookAway is ERC1155, Ownable, ERC1155Burnable {
    using SafeMath for uint256;
    uint256 collectionSize = 6789;
    uint256 private tokenPricePublic = 0.05 ether;
    uint256 private tokenPriceAllowlist = 0.03 ether;
    uint256 tokenId = 0;
    uint256 amountMinted = 0;
    uint256 maxPerWalletAllowlist = 1;
    uint256 maxPerWalletPublic = 1;
    mapping(address => uint256) public mintCount;
    mapping(address => uint256) public mintCountAllowlist;
    address revealContractAddress;
    bool isPrivateSaleEnabled = false;
    bool isPublicSaleEnabled = false;
    bool isSalesStarted = false;
    bool isBurnStarted = false;
    bytes32 public merkleRoot = 0x0;
    
    constructor() ERC1155("https://lookaway.xyz/api/metadata/{id}") { }

    function checkUserOnAllowlist(bytes32[] memory proof) view public returns(bool){
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on allowlist");
        return true;
    }

    function setMerkleRoot(bytes32 root) public onlyOwner {
        merkleRoot = root;
    }
    
    function setContractAddress(address _contractAddress) public onlyOwner {
        revealContractAddress = _contractAddress;
    }

    function setSalesActive(bool setting) public onlyOwner {
        isSalesStarted = setting;
    }

    function setPublicSaleActive(bool setting) public onlyOwner {
        isPublicSaleEnabled = setting;
    }

    function setAllowlistMintActive(bool setting) public onlyOwner {
        isPrivateSaleEnabled = setting;
    }

    function setIsBurnStarted(bool setting) public onlyOwner {
        isBurnStarted = setting;
    }

    function setPrices(uint256 allowlistPrice, uint256 publicPrice) public onlyOwner {
        tokenPricePublic = publicPrice;
        tokenPriceAllowlist = allowlistPrice;
    }

    function setMaxPerWallet(uint256 _public, uint256 _allowlist) public onlyOwner {
        maxPerWalletPublic = _public;
        maxPerWalletAllowlist = _allowlist;
    }

    function setCollectionSize(uint256 _size) public onlyOwner {
        collectionSize = _size;
    }

    function devMint() public onlyOwner returns(uint256) {
        uint256 amount = 1;
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= collectionSize, "Limit reached");
        amountMinted = amountMinted + amount;
        mintCount[msg.sender] += amount;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }

    function allowlistMint(uint256 amountToMint, bytes32[] calldata proof) public payable returns(uint256) {
        require(isSalesStarted == true, "Sales have not started.");
        uint256 amount = amountToMint;

        // Note: For public sales to be active, the bool isPublicSaleEnabled need to be true and the bool isPrivateSaleEnabled need to be false
        require(isPrivateSaleEnabled, "Allowlist sales have not started.");

        // Check Allowlist Merkle Proof
        require(MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not eligible for presale");

        // Add verification on ether required to pay
        require(msg.value >= tokenPriceAllowlist.mul(amount), "Not enough money");

        require(amount + amountMinted <= collectionSize, "Limit reached");
        require(mintCountAllowlist[msg.sender] + 1 <= maxPerWalletAllowlist, "You reached maximum mints per wallet.");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        amountMinted = amountMinted + amount;
        mintCountAllowlist[msg.sender] += amountToMint;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }

    function mint(uint256 _amount) public payable returns(uint256) {
        require(isSalesStarted == true, "Sales have not started.");
        uint256 amount = _amount;

        require(isPublicSaleEnabled, "Public sale has not started.");
        require(amount == 1, "You can only mint one token at a time.");
        require(mintCount[msg.sender] + 1 == maxPerWalletPublic, "You reached maximum mints per wallet.");

        // Price
        require(msg.value >= tokenPricePublic.mul(amount), "Not enough money");
        
        uint256 prevTokenId = tokenId;
        tokenId++;
        require(amount + amountMinted <= collectionSize, "Limit reached");
        amountMinted = amountMinted + amount;
        mintCount[msg.sender] += amount;
        _mint(msg.sender, tokenId, amount, "");
        return prevTokenId;
    }

    function setMaxQty (uint256 amount) public onlyOwner {
        collectionSize = amount;
    }
    
    function burnAndRevealToken(uint256 id) public returns(uint256) {
        require(isBurnStarted == true, "Burns has not begun!");
        require(balanceOf(msg.sender, id) > 0, "You do not own this token!"); // Check if the user own one of the ERC-1155
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        DesintationBurnContractI nftContract = DesintationBurnContractI (revealContractAddress);
        uint256 mintedId = nftContract.mintTransfer(msg.sender); // Mint the ERC-721 token
        return mintedId; // Return the minted ID
    }

    function forceBurnAndRevealToken(uint256 id) public onlyOwner {
        require(balanceOf(msg.sender, id) > 0, "Doesn't own the token");
        burn(msg.sender, id, 1); // Burn one the ERC-1155 token
        DesintationBurnContractI nftContract = DesintationBurnContractI (revealContractAddress);
        nftContract.mintTransfer(msg.sender); // Mint the ERC-721 token
    }
    
    function getPrice() view public returns(uint256) { 
        return tokenPricePublic;
    }
    
    function getAmountMinted() view public returns(uint256) {
        return amountMinted;
    }
    
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

}