// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title 
 *  a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Element", "ELT", _proxyRegistryAddress)
    {}


    function baseTokenURI() override public pure returns (string memory) {
        return "https://element-pixel.s3.ap-southeast-1.amazonaws.com/metadata/erc721/element/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://element-pixel.s3.ap-southeast-1.amazonaws.com/metadata/contract/element";
    }    

    function withdraw(uint256 amount) public onlyOwner{
        address payable addr = payable(owner());
        addr.transfer(amount);
    }

    /** 
    list all token for sender
     */
    function allToken() public view returns (uint256[] memory){
        uint256 count = balanceOf(msg.sender);
        require(count > 0,"your address have no token");
        uint256[] memory ids = new uint[](count);
        uint256 index = 0;
        for(uint256 i =1;i<=totalSupply();i++){
            if(ownerOf(i) == msg.sender){
                ids[index] = i;
                index++;
            }
            if(index == count){
                break;
            }
        }
        return ids;
    }
}
