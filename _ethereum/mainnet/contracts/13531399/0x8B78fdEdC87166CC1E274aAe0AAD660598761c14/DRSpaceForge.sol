// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./EnumerableSet.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./DRToken.sol";
import "./ITraitRegistry.sol";
import "./IRNG.sol";

import "./console.sol";

contract DRSpaceForge is Ownable {

    struct randomNumberRequest {
        address _address;
        uint16 mintedTokenId;
        uint256 random;
        bool fulfilled;
    }
    mapping(bytes32 => randomNumberRequest) randomNumberRequests;
    mapping(uint8 => uint8)     public traitSizes;
    mapping(uint16 => bytes32)  public tokenToHash;

    mapping(address => uint16[]) public userTokens;


    bool            public locked;
    uint256         public unlockTime = 1635778800;

    // contracts
    DRToken         public nft;
    IRNG            public rnd;
    ITraitRegistry  public traitRegistry;
    address                BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint16          public nextMintedTokenId = 4002;

    event Forged(uint256 tokenXId, uint256 tokenYId, uint256 tokenWId, uint256 tokenZId, uint256 mintedTokenId, bytes32 requestHash);
    event Claimed(uint256 mintedTokenId, bytes32 requestHash);


    constructor(
        address erc721,
        address _tr,
        address _rndContractAddress
        ) {

        nft = DRToken(erc721);
        traitRegistry = ITraitRegistry(_tr);
        rnd = IRNG(_rndContractAddress);

        // trait 0 => 10% discount trait - all 128 pieces -> TODO: update trait 0 -> range start 4000 - end 7000
        traitSizes[4] = 99;   // trait 4 - Print trait - 99 pieces
        traitSizes[5] = 9;    // trait 5 - ether card trait - 9 pieces
        traitSizes[6] = 4;    // trait 6 - custom trait - 4 pieces
        traitSizes[7] = 63;   // trait 7 - Robot Booster Pill redeem - 63 pieces
    }

    function forgeIT(uint256 tokenXId, uint256 tokenYId, uint256 tokenWId, uint256 tokenZId) public {

        uint16 mintedTokenId = nextMintedTokenId++;
        require(mintedTokenId < 4129, "DRSpaceForge: Max claim reached!");

        require(!locked && getBlockTimestamp() > unlockTime, "DRSpaceForge: Contract locked");

        require(nft.ownerOf(tokenXId) == msg.sender, "DRSpaceForge: Token X must be owned by message sender!");
        require(nft.ownerOf(tokenYId) == msg.sender, "DRSpaceForge: Token Y must be owned by message sender!");
        require(nft.ownerOf(tokenWId) == msg.sender, "DRSpaceForge: Token W must be owned by message sender!");
        require(nft.ownerOf(tokenZId) == msg.sender, "DRSpaceForge: Token Z must be owned by message sender!");

        require(
            validForge(
                getTokenCollectionById(tokenXId),
                getTokenCollectionById(tokenYId),
                getTokenCollectionById(tokenWId),
                getTokenCollectionById(tokenZId)
            ), "DRSpaceForge: Tokens cannot combine!"
        );
        
        // burn tokens 
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenXId);
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenYId);
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenWId);
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenZId);

        // Request a random number
        bytes32 hash = rnd.requestRandomNumberWithCallback();

        // make sure we don't have hash collistions
        if(randomNumberRequests[hash].mintedTokenId > 0) {
            // request again!
            hash = rnd.requestRandomNumberWithCallback();
            if(randomNumberRequests[hash].mintedTokenId > 0) {
                revert("DRSpaceForge: Random hash request collisions!");
            }
        }

        // link token id to requested hash
        randomNumberRequests[hash] = randomNumberRequest(msg.sender, mintedTokenId, 0, false);
        // reverse mapping
        tokenToHash[mintedTokenId] = hash;
        
        userTokens[msg.sender].push(mintedTokenId);
        emit Forged(tokenXId, tokenYId, tokenWId, tokenZId, mintedTokenId, hash);
    }

    // 9,10,11,12
    function validForge(uint256 collectionX, uint256 collectionY, uint256 collectionW, uint256 collectionZ) public pure returns ( bool ) {
        uint256 sum = collectionX + collectionY + collectionW + collectionZ;
        if (sum == 42) { // the meaning of life
            if( collectionX * collectionY * collectionW * collectionZ == 11880 ){
                return true;
            }
        }
        return false;         
    }

    // {name: "Summer High",           uri: "summer-high",         start: 5001,    end: 5500 },
    // {name: "Robot In The Sun",      uri: "robot-in-the-sun",     start: 5501,    end: 6000 },
    // {name: "Summer Fruits",         uri: "summer-fruits",       start: 6001,    end: 6500 },
    // {name: "Evolution",             uri: "evolution",           start: 6501,    end: 7000 },

    function getTokenCollectionById(uint256 _tokenId) public pure returns ( uint256 ) {
        require(_tokenId > 5000 && _tokenId < 7001, "DRSpaceForge: Token id does not participate");

        _tokenId--;
        return _tokenId / 500 - 1; // remove 1 because of 4500-5000 gap
    }

    function process(uint256 _random, bytes32 _requestHash) public {
        require(msg.sender == address(rnd), "DRSpaceForge: Unauthorised");

        // link _random result to requested hash
        randomNumberRequests[_requestHash].random = _random;

        randomNumberRequest storage request = randomNumberRequests[_requestHash];

        // Allocate traits to this new token.
        uint16 tokensLeftToAssign = 4128 - request.mintedTokenId + 1;

        // console.log("tokensLeftToAssign", tokensLeftToAssign);
        // console.log(traitSizes[4], traitSizes[5], traitSizes[6], traitSizes[7]);

        for(uint8 i = 4; i < 8; i++) {
            // decide index by random
            uint256 _index = _random % tokensLeftToAssign;

            // console.log("_random", _random, "_index", _index);
            if(_index < traitSizes[i]) {
                // set trait
                traitRegistry.setTrait(i, request.mintedTokenId, true);

                // decrement traitSize
                traitSizes[i]--;
            }

            // shift
            _random = _random >> 8;
        }

    }

    function claim(uint16 tokenId) public {

        bytes32 _requestHash = tokenToHash[tokenId];
        randomNumberRequest storage request = randomNumberRequests[_requestHash];
        require(request._address == msg.sender, "DRSpaceForge: not request owner.");
        require(request.random > 0, "DRSpaceForge: random number needs to be higher than 0");
        require(request.fulfilled == false, "DRSpaceForge: already claimed");

        // mint the new token
        nft.mintTo(msg.sender, 8);
        request.fulfilled = true;

        emit Claimed(request.mintedTokenId, _requestHash);
    }


    function numberOfTokens(address _address) external view returns ( uint256 length)  {
        return userTokens[_address].length;
    }

    function getStats(bytes32 hash) external view returns (address _address, uint16 mintedTokenId, uint256 random, bool fulfilled) {
        _address = randomNumberRequests[hash]._address;
        mintedTokenId = randomNumberRequests[hash].mintedTokenId;
        random = randomNumberRequests[hash].random;
        fulfilled = randomNumberRequests[hash].fulfilled;
    }

    function getStats(uint16 tokenId) external view returns (address _address, uint16 mintedTokenId, uint256 random, bool fulfilled) {
        bytes32 hash = tokenToHash[tokenId];
        _address = randomNumberRequests[hash]._address;
        mintedTokenId = randomNumberRequests[hash].mintedTokenId;
        random = randomNumberRequests[hash].random;
        fulfilled = randomNumberRequests[hash].fulfilled;
    }

    function isInitialized() external view returns (bool) {
        // would be nice to be able to check rnd.isAuthorised() && nft.operator status
        return ( 
            traitRegistry.addressCanModifyTrait(address(this), 4) && 
            traitRegistry.addressCanModifyTrait(address(this), 5) && 
            traitRegistry.addressCanModifyTrait(address(this), 6) && 
            traitRegistry.addressCanModifyTrait(address(this), 7)
        );
    }

    function getTraitSizes() public view returns (uint256, uint256, uint256, uint256) {
        return (
            traitSizes[4],
            traitSizes[5],
            traitSizes[6],
            traitSizes[7]
        );
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