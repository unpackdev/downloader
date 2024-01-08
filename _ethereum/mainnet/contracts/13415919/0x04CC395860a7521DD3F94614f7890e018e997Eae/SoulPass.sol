// SPDX-License-Identifier: MIT

// Soul Pass
// <3 LS Sanctuary team
// @glu

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SoulPass is ERC721Enumerable, Ownable {

    string public SOUL_PROVENANCE = "";
    string _baseTokenURI;
    uint256 public constant MAX_SOULPASS = 4999;
    bool public mintPaused = true;
    mapping (uint256 => bool) public soulClaimed;

    address lostSouls;

    constructor(
        address LostSoulsContract
        ) ERC721("SoulPass", "SP") {
        lostSouls = LostSoulsContract;
    }

    // Mint All SoulPass
    function claimAllSoulPass(uint256[] memory soulArray) public {
        uint256 supply = totalSupply();
        require( !mintPaused,                              "Mint paused" );
        // Check if we hit max
        require( supply < MAX_SOULPASS, "Exceeds maximum SoulPass supply" );
        require(soulArray.length % 2 == 0,"Send an even amount of Souls");

        for(uint256 i;i<soulArray.length;i+=2){
            claimSoulPass(soulArray[i],soulArray[i+1]);
        }
    }

    // returns array of souls you own that have not been claimed 
    function soulNotClaimed(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            if(!soulClaimed[i]){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokensId;
    }

    // Mint One SoulPass
    function claimSoulPass(uint256 soulOne, uint256 soulTwo) public {
		uint256 supply = totalSupply();
		require( !mintPaused,                              "Mint paused" );
		require( supply < MAX_SOULPASS, "Exceeds maximum SoulPass supply" );
		require(IERC721(lostSouls).ownerOf(soulOne) == msg.sender,"You do not own soul one");
		require(IERC721(lostSouls).ownerOf(soulTwo) == msg.sender,"You do not own soul two");
		// Already Claimed
		require(!soulClaimed[soulOne],"Soul one already claimed");
		require(!soulClaimed[soulTwo],"Soul two already claimed");

		soulClaimed[soulOne] = true;
		soulClaimed[soulTwo] = true;
         _safeMint( msg.sender, supply);   
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        SOUL_PROVENANCE = provenanceHash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    
    function pause(bool val) public onlyOwner {
        mintPaused = val;
    }

}