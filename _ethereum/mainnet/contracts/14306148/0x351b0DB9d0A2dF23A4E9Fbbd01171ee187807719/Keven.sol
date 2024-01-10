// SPDX-License-Identifier: Keven
/*

    Keven was here.

    First 100 free.
    0.0069 ether.

*/

pragma solidity ^0.8.7;

import "./ERC721Custom.sol";
import "./Strings.sol";
import "./Base64.sol";

contract INVISIBLE_KEVEN is ERC721 {
    
    using Strings for uint256;

    uint16 public constant kevens = 10000;
    string public constant NFTname = "Invisible Kevens";

    uint256 public PRICE_PER_MINT = 0.0069 ether;
    string description = "Invisible Kevens are a collection of Invisible Kevens. Every Keven is unique, but you can't see him because he's invisible.";
    string imageURL = "https://i.imgur.com/eKExiLs.jpg";

    constructor() ERC721(
        NFTname,
        NFTname,
        kevens)
    {

    }

    function setETHPrice(uint256 newPrice) external onlyOwner {
        PRICE_PER_MINT = newPrice;
    }

    function Buy(uint256 amount)  external payable  {

        require(amount > 0,"Mint > 1");
        
        uint256 totalCost = 0;

        if (_totalSupply16 > 100){
            totalCost = PRICE_PER_MINT * amount;
        }

        require(msg.value >= totalCost,"Not enough ETH");

        for (uint256 i = 0; i < amount; i++ ){
            _mint(msg.sender);
        }

        Egress(address(0),15 + (block.timestamp % 10));
    
    }

    function withdrawAll() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function tokenURIfallback(uint256 tokenID) public view override returns (string memory)
    {

        string memory attributes = string(abi.encodePacked(
                                        '"attributes": [ ',
                                            '{"trait_type":"Keven","value":"True"},', //',',    
                                            '{"trait_type":"Rarity","value":"',(tokenID % 10).toString(),'"}',
                                        ']'
                                    ));
        
        string memory json = Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name":"Invisible Keven #',(tokenID).toString(),
                                    '", "description": "',description,'", "image": "',imageURL,
                                    '",',attributes,'}'
                                )
                            )
                        )
                    );

        return string(abi.encodePacked("data:application/json;base64,", json));

    }

}