// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";


/// @title AmoebaXStarl
/// @notice A contract for amoebas in the STARL ecosystem
contract AmoebaXStarl is Ownable, ERC721 {
    using   SafeMath for uint256;
    using   Strings for uint256;

    event ArtistAdded(uint256 artistId, uint256 supply, uint256 startId, uint256 launchTime, address feeRecipient, string baseUrl, string extension);
    event FeePercentUpdated(uint256 devFeePercent, uint256 artistFeePercent);

    uint256 cost = 0.08 ether;

    /// @dev Satellite Info for each Sate NFT
    struct ArtistInfo {
        uint256 supply;
        uint256 minted;
        uint256 startId;
        uint256 launchTime;
        address feeRecipient;
        string  baseUrl;
        string  extension;
    }

    uint256 public devFeePercent = 10;
    uint256 public artistFeePercent = 30;

    address public devFeeRecipient;
    address public amoebaRecipient;

    uint256 artistIdPointer;
    mapping(uint256 => ArtistInfo) public artists;

    constructor (
        address _devFeeRecipient,
        address _amoebaRecipient,
        uint256[] memory supplies,
        uint256 launchTime,
        address[] memory feeRecipients,
        string[] memory baseUrls,
        string memory extension
    ) ERC721("Amoeba x STARL", "AMxST") {
        require(baseUrls.length == supplies.length, "Incorrect length of supplies");

        devFeeRecipient = _devFeeRecipient;
        amoebaRecipient = _amoebaRecipient;

        for(uint256 i=0; i<supplies.length; i++) {
            _addArtist(baseUrls[i], supplies[i], launchTime, feeRecipients[i], extension);
        }
    }

    function updateFeePercent(uint256 _devFeePercent, uint256 _artistFeePercent) public onlyOwner {
        require(_devFeePercent > 0 && _devFeePercent <= 50, "Invalid devFeePercen");
        require(_artistFeePercent > 0 && _artistFeePercent <= 50, "Invalid artistFeePercent");
        devFeePercent = _devFeePercent;
        artistFeePercent = _artistFeePercent;
        emit FeePercentUpdated(devFeePercent, artistFeePercent);
    }

    function addArtist(uint256 supply, uint256 launchTime, address feeRecipient, string memory baseUrl, string memory extension) public onlyOwner {
        _addArtist(baseUrl, supply, launchTime, feeRecipient, extension);
    }

    function batchAddArtists(uint256[] calldata supplies, uint256 launchTime, address[] calldata feeRecipients, string[] calldata baseUrls, string[] calldata extensions) public onlyOwner {
        require(baseUrls.length == supplies.length, "Incorrect length of supplies");
        
        for(uint256 i=0; i<supplies.length; i++) {
            _addArtist(baseUrls[i], supplies[i], launchTime, feeRecipients[i], extensions.length > i ? extensions[i] : extensions[0]);
        }
    }

    function _addArtist(string memory baseUrl, uint256 supply, uint256 launchTime, address feeRecipient, string memory extension) internal {
        require(launchTime > block.timestamp, "Invalid launch time");
        require(supply > 0, "Invalid supply of artist");
        uint256 startId = 1;
        if (artistIdPointer > 0) {
            startId = artists[artistIdPointer].startId + artists[artistIdPointer].supply;
        }
        artistIdPointer = artistIdPointer + 1;
        artists[artistIdPointer] = ArtistInfo(supply, 0, startId, launchTime, feeRecipient, baseUrl, extension);

        emit ArtistAdded(artistIdPointer, supply, startId, launchTime, feeRecipient, baseUrl, extension);
    }

    function mint(address _to, uint256 artistId) public payable {
        require(artistId <= artistIdPointer, "Invalid artist id");
        require(block.timestamp >= artists[artistId].launchTime, "Mint for this artist not started");

        ArtistInfo storage artist = artists[artistId];
        require(artist.minted < artist.supply, "All nfts are minted for this artistId");

        if (msg.sender != owner()) {
            require(msg.value >= cost);
            uint256 devFeeAmount = msg.value.mul(devFeePercent).div(100);
            (bool devFeeTransferSuccess,) = devFeeRecipient.call{value : devFeeAmount}("");
            require(devFeeTransferSuccess, "devFeeTransfer failed");

            uint256 artistFeeAmount = msg.value.mul(artistFeePercent).div(100);
            (bool artistFeeTransferSuccess,) = artist.feeRecipient.call{value : artistFeeAmount}("");
            require(artistFeeTransferSuccess, "artistFeeTransferSuccess failed");

            (bool amoebaFeeTransferSuccess,) = amoebaRecipient.call{value : msg.value.sub(devFeeAmount).sub(artistFeeAmount)}("");
            require(amoebaFeeTransferSuccess, "amoebaFeeTransferSuccess failed");
        }
        
        _safeMint(_to, artists[artistId].startId.add(artists[artistId].minted));
        artist.minted = artist.minted.add(1);
    }

    function _getArtistId(uint256 tokenId) internal view returns (uint256) {
        for(uint256 id=artistIdPointer; id>0; id--) {
            if (tokenId >= artists[id].startId) {
                return id;
            }
        }
        return 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        uint256 artistId = _getArtistId(tokenId);
        require(artistId>0, "Invalid artist id");
        uint256 index = tokenId.sub(artists[artistId].startId).add(1);
        return string(
            abi.encodePacked(
                abi.encodePacked(artists[artistId].baseUrl, index.toString()), 
                artists[artistId].extension
            )
        );
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }    
}