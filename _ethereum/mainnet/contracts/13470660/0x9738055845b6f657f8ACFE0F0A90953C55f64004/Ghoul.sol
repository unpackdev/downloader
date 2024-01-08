// SPDX-License-Identifier: MIT

// Grab a Ghoul, perfect pairing with your Soul 
// 
// <3 Lost Souls Sanctuary team
// @glu

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Ghoul is ERC721Enumerable, Ownable {

    string public GHOULS_PROVENANCE = "";
    string _baseTokenURI;
    uint256 public constant MAX_GHOULS = 5000;
    bool public mintPaused = true;
    uint256 public ghoulEndTime = 1664596799; // October 1st, 2022 00:00:00 GMT-0400

    // Soul Pass Mapping
    mapping (uint256 => bool) public soulPassClaimed;

    address soulPass;

    constructor(
        address SoulPassContract
        ) ERC721("Ghouls", "GHLS")  {
        soulPass = SoulPassContract;
        // Deployer gets first one
        _safeMint( msg.sender, 0);
    }

    // Mint All Ghouls
    function claimAllGhouls(uint256[] memory soulPassArray) public {
        uint256 supply = totalSupply();
        require( !mintPaused,                              "Mint paused" );
        // Check if we hit max
        require( supply < MAX_GHOULS, "Exceeds maximum SoulPass supply" );

        for(uint256 i;i<soulPassArray.length;i++){
            claimGhoul(soulPassArray[i]);
        }
    }

    // returns array of souls you own that have not been claimed 
    function ghoulNotClaimed(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            if(!soulPassClaimed[i]){
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokensId;
    }

    // Mint One SoulPass
    function claimGhoul(uint256 soulPassNum) public {
        uint256 supply = totalSupply();
        require( !mintPaused,                              "Mint paused" );
        require( supply < MAX_GHOULS, "Exceeds maximum Ghoul supply" );
        require(IERC721(soulPass).ownerOf(soulPassNum) == msg.sender,"You do not own the soul pass");
        // Check ig Already Claimed
        require(!soulPassClaimed[soulPassNum],"Soul Pass already claimed");
        // Check if past minting time
        require( block.timestamp <= ghoulEndTime,"Minting Over!");

        soulPassClaimed[soulPassNum] = true;
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
        GHOULS_PROVENANCE = provenanceHash;
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

    function setEndTime(uint256 _newGhoulEndTime) public onlyOwner {
        ghoulEndTime = _newGhoulEndTime;
    }

    function getEndTime() public view returns (uint256){
        return ghoulEndTime;
    }
}