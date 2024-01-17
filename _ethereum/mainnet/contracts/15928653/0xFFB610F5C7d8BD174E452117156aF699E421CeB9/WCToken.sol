pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./WCTokenDrawer.sol";

abstract contract WCToken is ERC1155Supply {
    uint256[5] public totalSupplys = [0,0,0,0,0];


    /*
    @notice Main function to mint country token (Similar to ERC20)
    @param recipient The address recepient of the token
    @param country index from 0-31 of the winning country
    @param amount Amount of tokens to bulk buy
    */
    function mintCountry(address recipient, uint8 country, uint256 amount)
    public
    payable
    returns (uint256)
    {  
        // No SC calling this function
        require(msg.sender == tx.origin);
        require(amount > 0);
        require(msg.value >= 0.005 ether * amount);
        require(country < 32);
        require(block.timestamp < 1671300692);
        totalSupplys[0] += amount;

        _mint(recipient, country, amount, "");

        return country;
    }

    /*
    @notice Function for creating secondary tokens, fusing 2 or 4 tokens together, for playing in minigames
    @param ids the ids of the tokens you want to fuse
    @param vdId The validatorId (index in the validator address array) of the msg Sender
    */
    function mintToken(address recipient, uint256[] memory ids, uint256 amount)
    public
    {  
        // No SC calling this function
        require(msg.sender == tx.origin);
        uint256 category = ids.length;
        if(category == 2){
            require(block.timestamp < 1670950869);
        } else {
            require(block.timestamp < 1670590869);
        }
        require(category ==2 || category ==4);
        require(ids[0] > 0);
        uint idRep = 0;
        uint256[] memory amounts  = new uint256[](category);
        for(uint i =0;i<category;i++){
            idRep <<= 5;
            require(ids[i] < 32);
            idRep += ids[i];
            amounts[i] = amount;
        }
        _burnBatch(recipient, ids, amounts);
        _mint(recipient, idRep, amount, "");
        totalSupplys[0] -= amount;
        totalSupplys[category] += amount;
    }

}
