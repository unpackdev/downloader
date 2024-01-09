// contracts/InterleaveArtistFactory.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";

import "./InterleaveArtistBase.sol";

contract InterleaveArtistFactory is Ownable {
    InterleaveArtistBase[] public artistNFTs;

    event ArtistNFTCreated(InterleaveArtistBase artistNFT);

    function createArtistNFT(string memory _baseURI, string memory _artistName) public onlyOwner {
        InterleaveArtistBase newArtistNFT = new InterleaveArtistBase(_baseURI, _artistName, msg.sender);
        artistNFTs.push(newArtistNFT);
        emit ArtistNFTCreated(newArtistNFT);
    }

    function getDeployedArtistNFTs() public view returns (InterleaveArtistBase[] memory) {
        return artistNFTs;
    }
}
