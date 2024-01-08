// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./SafeMath.sol";



interface IArrLandNFT {

    function spawn_pirate(address _to, uint256 generation, uint256 pirate_type) external returns (uint256);

}

contract ArrlandNFTPromo is Ownable {
    using SafeMath for uint256;

    uint256 public promoTokensCount;
    uint256 public CURRENT_TOKEN_ID;

    uint256[3] public mintLvlmax;

    address public arrlandNFT;

    event Sold(address to, uint256 tokenCount, uint256 amount, uint256 timestamp);

    constructor (address _arrlandNFT, uint256[3] memory _mintLvlmax) {
        arrlandNFT = _arrlandNFT;
        mintLvlmax = _mintLvlmax;    
    }

    function mint(uint256 numArrlanders) public payable{
        require(promoTokensCount < 2474, "Max promo");
        uint256 price;
        uint256 max_mint;
        if (CURRENT_TOKEN_ID < 200) {
            price = 40000000000000000;
            max_mint = mintLvlmax[0];
        } else {
            if (CURRENT_TOKEN_ID >= 200 && CURRENT_TOKEN_ID < 400){
                price = 45000000000000000;
                max_mint = mintLvlmax[1];
            } else {
                if (CURRENT_TOKEN_ID >= 400 && CURRENT_TOKEN_ID < 2500) {
                    price = 50000000000000000;
                    max_mint = mintLvlmax[2];
                }                    
            }                
        }
        require(numArrlanders > 0 && numArrlanders <= max_mint, "You can mint from 1 to {max_mint} ArrLanders");
        require(price.mul(numArrlanders) == msg.value, "Not enough Ether sent for this tx");
        promoTokensCount = promoTokensCount.add(numArrlanders);
        uint256 tokenId;
        for (uint i = 0; i < numArrlanders; i++) {    
            tokenId = IArrLandNFT(arrlandNFT).spawn_pirate(msg.sender, 0, 1);
        }
        CURRENT_TOKEN_ID = tokenId;
        emit Sold(msg.sender, numArrlanders, msg.value, block.timestamp);
    }

    function setParams(uint256[3] memory _mintLvlmax) public onlyOwner {        
        mintLvlmax = _mintLvlmax;
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }
}

