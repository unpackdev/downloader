// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol"; 

///@notice The full moon has released her curse and awakened something buried deep within every demon...
///@author iqbalsyamil.eth (github.com/2pai)
contract YOKAI is ERC1155, Ownable {

    using Strings for uint256;
    
    mapping(address => bool) private yokaiContracts;
    mapping(uint256 => bool) public yokaiTokenId;

    string private baseURI;
    string public name = "Yokai";
    string public symbol = "YOKAI";

    constructor(string memory _uri, uint256[] memory _tokenIds, uint256[] memory _amounts) ERC1155(_uri) {
        baseURI = _uri;
        yokaiTokenId[1] = true;
        yokaiTokenId[2] = true;
        _mintBatch(0x35E198caD5eDb47d3EA3A6943476e65a60F27222, _tokenIds, _amounts, "");
        _transferOwnership(0x35E198caD5eDb47d3EA3A6943476e65a60F27222);
    }

    function appendYokai(uint256 _tokenId)
        external 
        onlyOwner
    {
        yokaiTokenId[_tokenId] = true;
    }

    function setYokaiContractAddress(address _spiritAddress, bool status) 
        external
        onlyOwner
    {
        yokaiContracts[_spiritAddress] = status;
    }

    function burnYokaiForSomething(uint256 _typeSpirit, address _from, uint256 _amount)
        external 
    {
        require(yokaiContracts[msg.sender], "Invalid Caller");
        _burn(_from, _typeSpirit, _amount);
    }
    
    function setBaseURI(string calldata _uri) 
        external
        onlyOwner
     {
        baseURI = _uri;
    }

    function mintBatch(address[] calldata _to, uint256 _tokenId, uint256[] memory _amounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _to.length; i++) {
            _mint(_to[i], _tokenId, _amounts[i], "");
        }

    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            yokaiTokenId[typeId],
            "URI requested for invalid token type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }
}