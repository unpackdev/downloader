// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721EnumerableAlt.sol";
import "./Strings.sol";

contract PlanetX is ERC721EnumerableAlt, Ownable {

    using Strings for uint256;

    uint public maxSupply = 1111;

    uint maxMint = 10;

    string public baseURI = "ipfs://QmTRNdMr7gtTgpkRxDKPm2b2876K6QBbPdu6JeTmDECG7c/";

    bool isPublicMint;

    constructor() ERC721Alt("Planet X", "Planet X") {

    }

    function mint(uint _numToMint) external {

    	require(_numToMint > 0, "Enter a valid amount to mint");

        require(isPublicMint == true, "Minting isnt public");

    	uint tokenId = totalSupply();

    	address sender = _msgSender();

    	require(_numToMint <= maxMint);

    	require(tokenId + _numToMint <= maxSupply, "Max supply has been reached");

    	for(uint i = 0; i < _numToMint; i++) {

    		_safeMint(sender, tokenId + i);

    	}

    }

    function getTokensOfAddress(address _addr) public view returns(uint[] memory) {

        uint[] memory tempArray;

        uint totalSupply = totalSupply();

        //Because I don't store the balances of addresses, i assume the max amount of tokens the user holds is equal
        //to the total phoenix levels
        tempArray = new uint[](totalSupply);
        uint total = 0;
        for(uint i = 0; i < totalSupply; i++) {
            if(_owners[i] == _addr) {
                tempArray[total] = i;
                total++;
            }
        }

        uint[] memory finalArray = new uint[](total);
        for(uint i = 0; i < total; i++) {
            finalArray[i] = tempArray[i];
        }
        
        return finalArray;

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {

        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, tokenId.toString()));

    }

    function setBaseUri(string memory _baseURI) external onlyOwner {

        baseURI = _baseURI;

    }

    function toggleIsPublicMint() external onlyOwner {
        isPublicMint = !isPublicMint;
    }

}