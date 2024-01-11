// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";



contract iwwonAirlines is ERC1155, Ownable {
    using Strings for uint256;
    
    address private burnerContract;
    string private baseURI;

    mapping(uint256 => bool) public flights;



    event SetBaseURI(string indexed _baseURI);




    /* ************************************************************
    *       CONSTRUCTOR
    **************************************************************/
    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    /**
    * Creates new series or refill existing one
    */
    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
        
        /* update even the existing seeries - Important for uri function */
        for(uint i = 0; i < ids.length; i++) {
            flights[ids[i]]= true;
        }
        
    }

    function setBurnerContractAddress(address burnerContractAddress)
        external
        onlyOwner
    {
        burnerContract = burnerContractAddress;
    }

    /**
    *  Burn possible by burnerContract if burnerContract owns tokens
    */
    function burnForAddress(uint256 typeId, address burnTokenAddress,uint256 amount)
        external
    {
        require(msg.sender == burnerContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, amount);
    }

  
    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            flights[typeId],
            "URI requested for invalid series"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}