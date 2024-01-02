// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Address.sol";
import "./Ownable.sol";
import "./Verificator.sol";

contract MonolitifyCore is Ownable, Verificator {
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "Only EOA");
        _;
    }

    uint256 public indexer;

    constructor(address signer) Verificator("monolitify", "1", signer) {}

    struct ArtistInfo {
        address accountAddress;
        string accountName;
        string accountAvatar;
        bool isVerified;
        uint256 totalSongs;
        uint256 updatedAt;
        string[] songName;
        string[] songUrl;
        string[] songCover;
    }

    mapping(uint256 => ArtistInfo) public artistData;
    mapping(address => uint256) public artistIndex;
    mapping(uint256 => bool) public isUsedNonce;

    function setProfile(
        string calldata accountName,
        string calldata accountAvatar,
        bool isVerified,
        uint256 _nonce,
        bytes memory _signature
    ) public isSigned(_nonce, _signature) returns (bool) {
        require(isUsedNonce[_nonce] == false, "Nonce already used");
        ArtistInfo storage artist = artistData[
            indexer == 0 ? 1 : artistIndex[msg.sender] == 0
                ? indexer
                : artistIndex[msg.sender]
        ];
        artist.accountName = accountName;
        artist.accountAddress = msg.sender;
        artist.accountAvatar = accountAvatar;
        artist.isVerified = isVerified;
        artist.updatedAt = block.timestamp;
        indexer++;
        artistIndex[msg.sender] = indexer;
        isUsedNonce[_nonce] = true;
        return true;
    }

    function uploadSongs(
        string calldata songName,
        string calldata songUrl,
        string calldata songCover,
        uint256 _nonce,
        bytes memory _signature
    ) public isSigned(_nonce, _signature) {
        require(isUsedNonce[_nonce] == false, "Nonce already used");
        require(
            artistIndex[msg.sender] != 0,
            "Please update your profile first"
        );
        require(
            bytes(songName).length > 2 &&
                bytes(songUrl).length > 2 &&
                bytes(songCover).length > 2,
            "Please fill all the fields"
        );
        ArtistInfo storage artist = artistData[artistIndex[msg.sender]];

        artist.songName.push(songName);
        artist.songUrl.push(songUrl);
        artist.songCover.push(songCover);

        artist.totalSongs++;
        isUsedNonce[_nonce] = true;
    }

    function getAllData(
        uint256 start,
        uint256 end
    ) public view returns (ArtistInfo[] memory) {
        ArtistInfo[] memory id = new ArtistInfo[](start + end);
        for (uint256 i = start; i <= end; i++) {
            ArtistInfo storage member = artistData[i];
            id[i] = member;
        }
        return id;
    }
}
