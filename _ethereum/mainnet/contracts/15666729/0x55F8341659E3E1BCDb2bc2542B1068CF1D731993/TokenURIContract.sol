// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./console.sol";

// // Helper functions OpenZeppelin provides.
import "./Strings.sol";
import "./Base64.sol";

interface DataInter{
    function sectionOne(uint16 propId)external view returns(bytes memory);
    function sectionTwo(uint16 propId)external view returns(bytes memory);
    function sectionThree(uint16 propId)external view returns(bytes memory);
    function sectionFour(uint16 propId)external view returns(bytes memory);
}


contract TokenURIMaker {
    address public DATA_CONTRACT;
    DataInter immutable DataContract;
    
    constructor(address dataContract) {
        require(dataContract != address(0), "Please enter valid contract address");
 
        DATA_CONTRACT = dataContract;
        DataContract = DataInter(DATA_CONTRACT);
        
    }


    function getTokenUri(uint16 nftId)external view returns(string memory){

        bytes memory dataURI = abi.encodePacked(
            DataContract.sectionOne(nftId),
            DataContract.sectionTwo(nftId),
            DataContract.sectionThree(nftId),
            DataContract.sectionFour(nftId)
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

}
