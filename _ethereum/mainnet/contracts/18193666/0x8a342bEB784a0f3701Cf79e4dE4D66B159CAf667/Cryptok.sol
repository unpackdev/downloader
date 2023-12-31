// Web: https://Cryp-Tok.app
// TG:  https://t.me/CrypTokERC

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ERC6551AccountLib.sol";

contract Cryptok is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Cryp-tok", "CrypToK") {}

    uint256 numofAdvertisements;
    uint256 numOfVideos;
    uint256 numOfContentCreators;

    struct Advertisement {
        uint256 advertisementId;
        string name;
        address creator;
        string contentIpfsHash;
        string[] listOfKeywords;
        uint256[] listOfContentLinked;
        uint256 stakedAmount;
    }

    struct Video {
        uint256 videoId;
        string name;
        address creator;
        uint256 contentTokenID;
        string contentURI;
        string contentIpfsHash;
        string[] listOfKeywords;
        uint256[] listOfAdvertisementsLinked;
        uint256 numOfLikes;
        address[] likedAddresses;
        uint256 amountOfEthCollected;
    }

    struct ContentCreator {
        address walletAddress;
        string username;
        uint256 totalVideoLikes;
        bool isWorldcoinVerified;
        bool isAdvertiser;
        bool isRegistered;
    }

    mapping(uint256 => Advertisement) public _advertisements;
    mapping(uint256 => Video) public _videos;
    mapping(address => ContentCreator) public _contentCreators;

    function registerAccount(
        string memory _username,
        bool _isAdvertiser
    ) public {
        require(_contentCreators[msg.sender].isRegistered == false, "You have already registered your account");
        require(bytes(_username).length > 0, "There musnpt be a username to your advertisment");

        ContentCreator storage newContentCreator = _contentCreators[msg.sender];

        newContentCreator.walletAddress = msg.sender;
        newContentCreator.username = _username;
        newContentCreator.totalVideoLikes = 0;
        newContentCreator.isAdvertiser = _isAdvertiser;
        newContentCreator.isRegistered = true;
    }

    function createAdvertisement(
        string memory _name, 
        string memory _contentIpfsHash, 
        string[] memory _listOfKeywords,
        uint256 _stakedAmount
    ) payable public {
        require(bytes(_name).length > 0, "No name to your advertisment");
        require(bytes(_contentIpfsHash).length > 0, "No asset to your advertisment");
        require(_listOfKeywords.length <= 10, "Up to 10 keywords");
        require(_stakedAmount > 0, "Staked amount must be greater than zero ETH");
        require(msg.value == _stakedAmount, "Value sent == specified staked amount");
        require(_contentCreators[msg.sender].isAdvertiser == true, "!videos if content creator");

        Advertisement storage newAdvertisement = _advertisements[numofAdvertisements];

        newAdvertisement.advertisementId = numofAdvertisements;
        newAdvertisement.name = _name;
        newAdvertisement.creator = msg.sender;
        newAdvertisement.contentIpfsHash = _contentIpfsHash;
        newAdvertisement.listOfKeywords = _listOfKeywords;
        newAdvertisement.stakedAmount = _stakedAmount;

        numofAdvertisements++;
    } 

    function createVideo(
        string memory _name,
        string memory _contentIpfsHash,
        string[] memory _listOfKeywords,
        string memory uri
    ) public {
        require(bytes(_name).length > 0, "name to your video");
        require(bytes(_contentIpfsHash).length > 0, "Video to your upload");
        require(_listOfKeywords.length <= 10, "up to 10 keywords");
        require(bytes(uri).length > 0, "URI to your video");
        require(_contentCreators[msg.sender].isAdvertiser == false, "!videos Advertiser");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        Video storage newVideo = _videos[numOfVideos];

        newVideo.videoId = numOfVideos;
        newVideo.name = _name;
        newVideo.creator = msg.sender;
        newVideo.contentTokenID = tokenId;
        newVideo.contentURI = uri;
        newVideo.contentIpfsHash = _contentIpfsHash;
        newVideo.listOfKeywords = _listOfKeywords;
        newVideo.numOfLikes = 0;
        newVideo.amountOfEthCollected = 0;

        numOfVideos++;
    }  

    function likeVideo(uint256 _videoId) public {
        Video storage video = _videos[_videoId];

        uint256 count = 0;

        for (uint256 i = 0 ; i < video.likedAddresses.length ; ++i) {
            if (video.likedAddresses[i] != msg.sender) {
                count++;
            }
        }

        require(count == video.likedAddresses.length, "You have already liked the post");

        video.numOfLikes++;
        video.likedAddresses.push(msg.sender);

        _contentCreators[video.creator].totalVideoLikes++;
    }

    function getAdFunds(uint256 _tokenId, address _tokenContract, uint256 _advertisementId, uint256 _videoId) public payable {
        Advertisement storage advertisement = _advertisements[_advertisementId];
        Video storage video = _videos[_videoId];

        uint256 count = 0;

        for (uint256 i = 0 ; i < video.listOfAdvertisementsLinked.length ; ++i) {
            if (video.listOfAdvertisementsLinked[i] == _advertisementId) {
                count++;
            }
        }

        require(count != 0, "This advertisement is not linked to your video");

        uint256 numberOfLikes = video.numOfLikes;

        // Calculate the total amount to be distributed to likes
        uint256 totalAmountToDistribute = numberOfLikes * 0.01 ether;

        require(advertisement.stakedAmount >= totalAmountToDistribute, "Not enough funds in the advertisement for the likes");

        advertisement.stakedAmount -= totalAmountToDistribute;

        address registry = 0x02101dfB77FDE026414827Fdc604ddAF224F0921;
        address implementation = 0x2D25602551487C3f3354dD80D76D54383A243358;
        uint256 chainId = 80001; // Polygon Mumbai
        address tokenContract = _tokenContract;
        uint256 tokenId = _tokenId;
        uint _salt = 0;

        address tbaAddress = ERC6551AccountLib.computeAddress(registry, implementation, chainId, tokenContract, tokenId, _salt);

        (bool success, ) = tbaAddress.call{value: totalAmountToDistribute, gas: 2300}("");
        require(success, "Transfer to creator failed");

        video.amountOfEthCollected += totalAmountToDistribute;
    }

    function matchAdContent(uint256 _advertisementId, uint256 _videoId) public {
        require(_contentCreators[msg.sender].isAdvertiser == true, "Must be Advertiser");
        Advertisement storage advertisement = _advertisements[_advertisementId];
        Video storage video = _videos[_videoId];

        advertisement.listOfContentLinked.push(_videoId);
        video.listOfAdvertisementsLinked.push(_advertisementId);
    }
  
    // View functions 
    function getContentCreatorInfo(address _contentCreator) public view returns (
        address, string memory, uint256, bool, bool, bool
    ) {
        return (
            _contentCreators[_contentCreator].walletAddress,
            _contentCreators[_contentCreator].username,
            _contentCreators[_contentCreator].totalVideoLikes,
            _contentCreators[_contentCreator].isWorldcoinVerified,
            _contentCreators[_contentCreator].isAdvertiser,
            _contentCreators[_contentCreator].isRegistered
        );
    }
    
    function getAdvertisement(uint256 _advertisementId) public view returns (
        uint256, string memory, address, string memory, string[] memory, uint256[] memory, uint256
    ) {
        return (
            _advertisements[_advertisementId].advertisementId,
            _advertisements[_advertisementId].name,
            _advertisements[_advertisementId].creator,
            _advertisements[_advertisementId].contentIpfsHash,
            _advertisements[_advertisementId].listOfKeywords,
            _advertisements[_advertisementId].listOfContentLinked,
            _advertisements[_advertisementId].stakedAmount
        );
    }

    function getVideo(uint256 _videoId) public view returns (
        uint256, string memory, address, string memory, string[] memory, uint256[] memory
    ) {
        return (
            _videos[_videoId].videoId,
            _videos[_videoId].name,
            _videos[_videoId].creator,
            _videos[_videoId].contentIpfsHash,
            _videos[_videoId].listOfKeywords,
            _videos[_videoId].listOfAdvertisementsLinked
        );
    }

    function getVideoBlockchainDetails(uint256 _videoId) public view returns (uint256, string memory, uint256) {
        return (
            _videos[_videoId].contentTokenID,
            _videos[_videoId].contentURI,
            _videos[_videoId].amountOfEthCollected
        );
    }

    function getVideoLikesInfo(uint256 _videoId) public view returns (uint256, address[] memory) {
        return (
            _videos[_videoId].numOfLikes, 
            _videos[_videoId].likedAddresses
        );
    }

    function getNumbers() public view returns (uint256, uint256, uint256) {
        return (numofAdvertisements, numOfVideos, numOfContentCreators);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
