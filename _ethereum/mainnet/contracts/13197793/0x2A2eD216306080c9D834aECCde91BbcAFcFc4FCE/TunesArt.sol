//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract TunesArt is Ownable{

    struct TuneData{
        string coverArtUri;
        string tuneSongUri;
        string lyricsUri;
        string twitterHandle;
        string metadataUri;
    }

    event TuneDataUpdate(
        address indexed owner,
        uint tokenid,
        string coverArtUri,
        string tuneSongUri,
        string lyricsUri,
        string twitterHandle
    );

    mapping(uint => TuneData) public tunesMetaData;
    uint public support;
    bool public reentrancy;
    IERC721Enumerable public tunes = IERC721Enumerable(0xfa932d5cBbDC8f6Ed6D96Cc6513153aFa9b7487C);

    function getTokenOwner(uint tokenId) public view returns (address owner) {
        require (tokenId < tunes.totalSupply(), 'invalid tokenID');
        return tunes.ownerOf(tokenId);
    }

    function getTuneMetaData(uint tokenId) public view returns (string memory coverArtUri, string memory tuneSongUri, string memory lyricsUri, string memory twitterHandle, string memory metadataUri) {
        require (tokenId < tunes.totalSupply(), 'invalid tokenID');
        TuneData memory tuneData = tunesMetaData[tokenId];
        return (tuneData.coverArtUri, tuneData.tuneSongUri, tuneData.lyricsUri, tuneData.twitterHandle, tuneData.metadataUri);  
    }

    function setTuneMetaData(uint tokenId, string calldata coverArtUri, string calldata tuneSongUri, string calldata lyricsUri, string calldata twitterHandle, string calldata metadataUri) public payable {
        if (reentrancy == false) {
            reentrancy = true;
            require (msg.sender == getTokenOwner(tokenId), 'invalid token owner');

            if (support > 0) {
                require (msg.value >= support, 'kindly pay to support this project');
                (bool sent, bytes memory data) = owner().call{value: msg.value}("");
                require(sent, "Failed to send Ether");  
            }
            TuneData memory tuneData = TuneData(coverArtUri, tuneSongUri, lyricsUri, twitterHandle, metadataUri);
            tunesMetaData[tokenId] = tuneData;
            emit TuneDataUpdate(msg.sender, tokenId, coverArtUri, tuneSongUri, lyricsUri, twitterHandle);
            reentrancy = false;
        }
    }

    function setSupport(uint _support) public onlyOwner{
        support = _support;
    }
}
