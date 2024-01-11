// SPDX-License-Identifier: MIT

/*
            Supply: 5560.
            Total Free Supply: 4560.
            Loopable: yes (on purpose, to save gas).
            Max per TX: 10.
            Mint Price: First 4560 free & then 0.005!
            Mint Function: mint.
            Parameters: amount.
*/


pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./Ownable.sol";


contract goblindwarftownwtf is ERC721A, Ownable {
    
    // -------------------------------------//
    //              Configuration           //
    // -------------------------------------//
    uint256 public constant MAX_SUPPLY = 5560;
    uint256 public TOTAL_FREE_SUPPLY;
    string private BASE_URI;
    uint256 IS_MAX_PER_TX;
    bool IS_PUBLIC_SALE_ACTIVE;
    uint256 public MINT_PRICE;

    // -------------------------------------//
    //              Constructor             //
    // -------------------------------------//
    constructor() ERC721A("goblindwarftown.wtf", "goblindwarftown.wtf"){
        BASE_URI = "ipfs://QmUHKoMw8dcm9kFVKMFBHWE2dhKAUiiw5YzQdnDGujR4ik/";
        IS_MAX_PER_TX = 10;
        TOTAL_FREE_SUPPLY = 4560;
        IS_PUBLIC_SALE_ACTIVE = false; 
        MINT_PRICE = 0.005 ether;
        _safeMint(msg.sender, 1); 
    }

    // -------------------------------------//
    //          Mint ourself 500 NFTs       //
    // -------------------------------------//
    function getTrending() external onlyOwner {
        require(totalSupply() + 500 <= MAX_SUPPLY, "goblindwarftown.wtf :: Not enough supply left.");
        _safeMint(msg.sender, 500);
    }

    // -------------------------------------//
    //          Mint for public             //
    // -------------------------------------//
    function mint(uint256 amount) payable external  {       
        require(IS_PUBLIC_SALE_ACTIVE, "goblindwarftown.wtf :: Sale is inactive.");
        uint price = MINT_PRICE;
        if(totalSupply() + amount <= TOTAL_FREE_SUPPLY) price = 0;
        require(msg.value >= price * amount, "goblindwarftown.wtf :: Please send the correct value.");
        require(tx.origin == msg.sender, "goblindwarftown.wtf :: Please be yourself, not a contract.");
        require(amount <= IS_MAX_PER_TX, "goblindwarftown.wtf :: Max mints per TX");
        require(totalSupply() + amount <= MAX_SUPPLY, "goblindwarftown.wtf :: The supply cap is reached.");
        _safeMint(msg.sender, amount);
    }

    // -------------------------------------//
    //          Metadata sender             //
    // -------------------------------------//
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "URI query for non-existent token");
        return string(abi.encodePacked(BASE_URI, _toString(_tokenId), ".json"));
    }

    // -------------------------------------//
    //          Makes token id 0 -> 1       //
    // -------------------------------------//
    function _startTokenId() internal view virtual override(ERC721A) returns(uint256) {
        return 1;
    }

    // -------------------------------------//
    //              Setters                 //
    // -------------------------------------//
    function setPublicSale(bool setActive, string memory _baseURI, uint8 maxPerTx, uint256 price, uint256 _free) external onlyOwner {
        IS_PUBLIC_SALE_ACTIVE = setActive;
        BASE_URI = _baseURI;
        IS_MAX_PER_TX = maxPerTx;
        MINT_PRICE = price;       
        TOTAL_FREE_SUPPLY = _free; 
    }

    function activatePublicSale() external onlyOwner {
        IS_PUBLIC_SALE_ACTIVE = !IS_PUBLIC_SALE_ACTIVE;
    }
        
    // -------------------------------------//
    //          Withdraw Funds              //
    // -------------------------------------//
    function withdraw() external onlyOwner {
        require(address(this).balance != 0, "goblindwarftown.wtf :: No funds to withdraw.");
        address payoutAddress = 0x00e90Aa319c3d2A6D0bda0dcb0f917DAe7E7bE50; 
        (bool success, ) = payoutAddress.call{value: address(this).balance}("");
        require(success, "goblindwarftown.wtf :: ETH transfer failed");
    }
   
}