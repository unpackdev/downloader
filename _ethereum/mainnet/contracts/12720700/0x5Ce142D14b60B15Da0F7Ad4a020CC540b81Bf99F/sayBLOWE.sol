// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "./ERC721.sol";
import "./Ownable.sol";
import "./youtube.sol";

contract SayBLOWE is ERC721, ChainlinkYoutube, Ownable{
    uint256 public tokenCounter;
    constructor () public ERC721 ("sayBLOWE", "Artist"){
        tokenCounter = 0;
    }

    function createCollectible(string memory _uri) public onlyOwner returns (uint256) {
        uint256 newItemId = tokenCounter;
        uriDetails storage data = dataInfo[newItemId];
        data.token_id = newItemId;
        data.uri = _uri;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _uri);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }
    
    function updateCollectiables(uint256 _tokenID, string memory _tokenUri, uint256 _dynamicRating, string memory _twitter_username, string memory _youtube_id)public onlyOwner{
        require(_exists(_tokenID), "SayBLOWE: can not update nonexistent token");
        uriDetails storage data = dataInfo[_tokenID];
        data.dynamicRating = _dynamicRating;
        data.uri = _tokenUri;
        _setTokenURI(_tokenID, _tokenUri);
        updateFollowerCount(_tokenID, _twitter_username, _youtube_id);
         
    }

}