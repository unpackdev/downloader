// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./DRToken.sol";
import "./ITraitRegistry.sol";
import "./IRNG.sol";

import "./console.sol";

contract SCRedeem is Ownable {

    struct randomNumberRequest {
        uint16 tokenId;
        uint16 mintedTokenId;
        uint8 mintCollection;
    }
    mapping(bytes32 => randomNumberRequest) randomNumberRequests;
    mapping(uint8 => uint8) public collectionSizes;
    mapping(uint16 => bytes32) public tokenToHash;

    bool            public locked;
    uint256         public unlockTime = 1633618800;

    // contracts
    DRToken         public nft;
    IRNG            public rnd;
    ITraitRegistry  public traitRegistry;

    event Redeem(uint16 sourceTokenId, bytes32 randomRequestHash);
    event Claim(uint16 sourceTokenId, bytes32 randomRequestHash, uint16 mintedTokenId);

    constructor(
        address erc721,
        address _tr,
        address _rndContractAddress
        ) {
        nft = DRToken(erc721);
        traitRegistry = ITraitRegistry(_tr);
        rnd = IRNG(_rndContractAddress);

        collectionSizes[0] = 128;   // sunflower
        collectionSizes[1] = 32;    // crystalhigh
        collectionSizes[2] = 16;    // flowergirl
    }

    function claimSC(uint16 tokenId) public {
        require(!locked && getBlockTimestamp() > unlockTime, "SCRedeem: Contract locked");

        require(nft.ownerOf(tokenId) == msg.sender, "SCRedeem: Token must be owned by message sender!");

        // Does the token have the correct Charm reedeem trait?
        require(traitRegistry.hasTrait(3, tokenId), "SCRedeem: Trait not found");

        // Request a random number
        bytes32 hash = rnd.requestRandomNumberWithCallback();

        // make sure we don't have hash collistions
        if(randomNumberRequests[hash].tokenId > 0) {
            // request again!
            hash = rnd.requestRandomNumberWithCallback();
            if(randomNumberRequests[hash].tokenId > 0) {
                revert("SCRedeem: Random hash request collisions!");
            }
        }

        // link token id to requested hash
        randomNumberRequests[hash] = randomNumberRequest(tokenId, 0, 0);
        // reverse mapping
        tokenToHash[tokenId] = hash;

        // remove trait from token
        traitRegistry.setTrait(3, tokenId, false);

        emit Redeem(tokenId, hash);
    }

    function process(uint256 _random, bytes32 _requestHash) public {
        require(msg.sender == address(rnd), "SCRedeem: Unauthorised");

        // find out how many charms we have left
        uint8 leftSize = collectionSizes[0] + collectionSizes[1] + collectionSizes[2];

        // decide index by random
        uint256 _index = _random % leftSize;

        // figure out collection to mint from
        uint8 mint_from_collection = 0;

        uint256 _currentSize = 0;
        for(uint8 i = 0; i < 3; i++) {
            _currentSize+= collectionSizes[i];
            if(_index < _currentSize) {
                mint_from_collection = i;
                i = leftSize;
            }
        }

        // decrement size by 1 for the collection we're minting from
        collectionSizes[mint_from_collection]--;

        // 7001 - 7128 Sunflower - uri sunflower - 128 pieces total - series 13
        // 7501 - 7532 Crystal High - uri crystalhigh 32 pieces total - series 14
        // 8001 - 8016 Flower Girl - uri flowergirl 16 pieces total - series 15
        
        // offset collection
        randomNumberRequests[_requestHash].mintCollection = mint_from_collection + 13;
    }

    function claim(bytes32 _requestHash) public {

        randomNumberRequest storage request = randomNumberRequests[_requestHash];
        address tokenOwner = nft.ownerOf(request.tokenId);

        require(msg.sender == tokenOwner, "SCRedeem: Token must be owned by message sender!");
        require(request.mintCollection > 0, "SCRedeem: mintCollection not resolved!");
        require(request.mintedTokenId == 0, "SCRedeem: already claimed!");

        // mint the charm NFT to the current owner of the token
        nft.mintTo(tokenOwner, request.mintCollection);

        // determine minted token id
        uint256 ownedtokenCount = nft.balanceOf(tokenOwner);
        uint256 mintedTokenId = nft.tokenOfOwnerByIndex(tokenOwner, ownedtokenCount - 1);

        // save it
        request.mintedTokenId = uint16(mintedTokenId);

        emit Claim(request.tokenId, _requestHash, request.mintedTokenId);
    }


    function getStats(bytes32 hash) external view returns (uint16 tokenId, uint16 mintedTokenId, uint8 mintCollection)  {
        tokenId = randomNumberRequests[hash].tokenId;
        mintedTokenId = randomNumberRequests[hash].mintedTokenId;
        mintCollection = randomNumberRequests[hash].mintCollection;
    }

    function isInitialized() external view returns (bool) {
        // would be nice to be able to check rnd.isAuthorised()
        return traitRegistry.addressCanModifyTrait(address(this), 3);
    }

    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    function removeUnlockTime() public onlyOwner {
        unlockTime = block.timestamp;
    }

    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /// blackhole prevention methods
    function retrieveERC20(address _tracker, uint256 amount)
        external
        onlyOwner
    {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }

}