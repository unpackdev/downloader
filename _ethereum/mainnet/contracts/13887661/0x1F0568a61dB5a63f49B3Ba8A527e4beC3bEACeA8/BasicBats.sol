// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enum.sol";

abstract contract BasicBats is ERC721Enum, Ownable, ReentrancyGuard {
    
    uint private basicBatUnitPrice = 0.07 ether;
    
    bool public presaleOpen = false;
    bool public publicSaleOpen = false;

    uint public MAX_MINT = 10;
    uint public MAX_SUPPLY = 6000;

    // withdraw addresses
    address projectAddr = 0x95Afac888021ae5Bc106Fb5999dC3918260FcF9d;
    address devAddr = 0xF97BACE652409fa832FaaC074bb1A9BaEE845C8b;
    
    /*************************************************
     * 
     *      MINT PART
     * 
     * ***********************************************/
    
    
    /*
    * The mint function
    */
    function _mintBasicBats(uint _num, uint _price, address _to) internal {
        uint supply = totalSupply();
        require( _num <= MAX_MINT, "Can only mint 10 bats per transaction");
        require( msg.value >= _price * _num, "Not enough ether sent" );
        require( supply + _num <= MAX_SUPPLY, "Max supply reached");

        for(uint i; i < _num; i++){
            _safeMint( _to, supply + i );
        }
        
        delete supply;
    }

    function airdropBasicBats(uint _num, address _address) external payable onlyOwner nonReentrant {
        _mintBasicBats(_num, 0, _address);
    }
    
    function mintBasicBats(uint _num) external payable nonReentrant {
        require(publicSaleOpen);
        
        _mintBasicBats(_num, basicBatUnitPrice, msg.sender);
    }
    
    /*************************************************
     * 
     *      UTILITY PART
     * 
     * ***********************************************/
     
    function switchPublicSaleStatus() external onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function updatePrice(uint _price) external onlyOwner {
        basicBatUnitPrice = _price;
    }

    function withdraw() external payable onlyOwner {
        uint devPercent = address(this).balance / 10;
        uint projectPercent = address(this).balance - devPercent;
        require(payable(projectAddr).send(projectPercent));
        require(payable(devAddr).send(devPercent));
    }

}