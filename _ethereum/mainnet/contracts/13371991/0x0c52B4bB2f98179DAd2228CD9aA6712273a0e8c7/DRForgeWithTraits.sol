// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "./SafeMath.sol";
import "./Ownable.sol";
import "./DRToken.sol";
import "./ITraitRegistry.sol";
import "./console.sol";

contract DRForgeWithTraits is Ownable {

    using SafeMath for uint256;

    address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    DRToken nft;
    ITraitRegistry traitRegistry;

    mapping(uint8 => uint256) tokenCount;
    mapping(uint8 => mapping(uint8 => uint256)) traitSizes;
    mapping(uint8 => uint256) offsetters;
    uint8 traitLength = 5;
    uint256 offsetter;
    uint256 constant TOKENS_IN_COLLECTION = 500;
    mapping(uint8 => uint256) mintedCount;
    
    bool    public locked;
    uint256 public unlockTime = 1633618800;

    event Forged(uint256 tokenAId, uint256 tokenBId, uint256 mintedTokenId);

    constructor(address erc721, address _tr) {
        nft = DRToken(erc721);
        traitRegistry = ITraitRegistry(_tr);

        offsetter = uint256(blockhash(block.number - 1));
        for(uint8 i = 0; i < 4; i++) {
            traitSizes[i][1] = 5;     // 50% discount
            traitSizes[i][2] = 50;    // redeem
            traitSizes[i][3] = 44;    // charm
            offsetters[i] = offsetter >> i * 4;
            tokenCount[i] = TOKENS_IN_COLLECTION;
        }
    }

    function forgeIT(uint256 tokenAId, uint256 tokenBId) public {
        require(!locked && getBlockTimestamp() > unlockTime, "Contract locked");

        require(nft.ownerOf(tokenAId) == msg.sender, "Forge: Token A must be owned by message sender!");
        require(nft.ownerOf(tokenBId) == msg.sender, "Forge: Token B must be owned by message sender!");
 
        uint256 collectionA = getTokenCollectionById(tokenAId);
        uint256 collectionB = getTokenCollectionById(tokenBId);

        (bool valid, uint256 mint_from_collection) = validForge(collectionA, collectionB);
        require(valid, "Forge: Tokens cannot combine!");
        
        // burn tokens 
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenAId);
        nft.transferFrom(msg.sender, BURN_ADDRESS, tokenBId);

        // make sure they're burned
        require(nft.ownerOf(tokenAId) == BURN_ADDRESS, "Forge: Token A must be burned!");
        require(nft.ownerOf(tokenBId) == BURN_ADDRESS, "Forge: Token B must be burned!");
        nft.mintTo(msg.sender, mint_from_collection);
        
        // uint256 ownedtokenCount = nft.balanceOf(msg.sender);
        // uint256 mintedTokenId = nft.tokenOfOwnerByIndex(msg.sender, ownedtokenCount.sub(1));

        uint256 mintedTokenId = setTraits(uint8(mint_from_collection) - 9);
        emit Forged(tokenAId, tokenBId, mintedTokenId);
    }

    function setTraits(uint8 traitCollection) internal returns (uint16 mintedTokenId) {
        uint256 realtiveId = TOKENS_IN_COLLECTION - tokenCount[traitCollection] + 1;
        mintedTokenId = 5000 + ( traitCollection * uint16(TOKENS_IN_COLLECTION) ) + uint16(realtiveId);

        uint8 traitId = getTrait(traitCollection, realtiveId);
        
        if(traitId == 0) {
            // 10% discount on
            // No need to set it as it's on by default
            // traitRegistry.setTrait(0, mintedTokenId, true);

        } else if(traitId == 1) {
            // set 10% discount off
            traitRegistry.setTrait(0, mintedTokenId, false);
            // 50% discount overrides 10% discount .. so set it on
            traitRegistry.setTrait(traitId, mintedTokenId, true);

        } else {
            // set 10% discount on
            // No need to set it as it's on by default
            // traitRegistry.setTrait(0, mintedTokenId, true);
            // set other trait on
            traitRegistry.setTrait(traitId, mintedTokenId, true);
        }
    }

    function getTrait(uint8 collection, uint256 realtiveId) internal returns (uint8 traitId) {
        uint256 _index = offsetters[collection] / realtiveId % tokenCount[collection];

        uint256 offset = 0;
        for(uint8 i = 0; i <= traitLength; i++) {
            uint256 _currentTraitSize = traitSizes[collection][i];
            offset+= _currentTraitSize;

            if(_index < offset) {

                // found trait
                traitSizes[collection][i]--;
                tokenCount[collection]--;
                return i;
            }
        }

        tokenCount[collection]--;
        return 0;
    }

    function toggleLocked () public onlyOwner {
        locked = !locked;
    }

    function removeUnlockTime () public onlyOwner {
        unlockTime = block.timestamp;
    }

    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    // B must be A + 1 or A must be B + 1, AND modulo of 2 must be 0
    function validForge(uint256 collectionA, uint256 collectionB) public pure returns ( bool valid, uint256 mint_from_collection ) {
        valid = false; 
        uint256 sum = collectionA.add(collectionB);
        if(sum == 1 || sum == 5 || sum == 9 || sum == 13) {
            bool rule1 = ( collectionA == collectionB.add(1) || collectionB == collectionA.add(1) );
            if(rule1) {
                mint_from_collection = 9;
                if(sum > 1) {
                    mint_from_collection = mint_from_collection.add( sum.div(4) ); 
                }
                valid = true;
            }
        }
    }

    /*
        
        Participating tokens

        {name: "Summer High (D)",       uri: "summerhigh-day",      start: 1,       end: 500 },
        {name: "Summer High (N)",       uri: "summerhigh-night",    start: 501,     end: 1000 },
        {name: "Robot In The Sun (D)",  uri: "robotinthesun-day",   start: 1001,    end: 1500 },
        {name: "Robot In The Sun (N)",  uri: "robotinthesun-night", start: 1501,    end: 2000 },
        {name: "Summer Fruits (D)",     uri: "summerfruits-day",    start: 2001,    end: 2500 },
        {name: "Summer Fruits (N)",     uri: "summerfruits-night",  start: 2501,    end: 3000 },
        {name: "Evolution (D)",         uri: "evolution-day",       start: 3001,    end: 3500 },
        {name: "Evolution (N)",         uri: "evolution-night",     start: 3501,    end: 4000 },
    */
    function getTokenCollectionById(uint256 _tokenId) public pure returns ( uint256 ) {
        require(_tokenId < 4001, "Token id does not participate");

        if(_tokenId > 1) {
           _tokenId = _tokenId.sub(1);
        }
        return _tokenId.div(500);
    }


    function getTokenCounts() public view returns (uint256 collection_1, uint256 collection_2, uint256 collection_3, uint256 collection_4) {
        return (
            TOKENS_IN_COLLECTION - tokenCount[0],
            TOKENS_IN_COLLECTION - tokenCount[1],
            TOKENS_IN_COLLECTION - tokenCount[2],
            TOKENS_IN_COLLECTION - tokenCount[3] 
        );
    }

    function getTraitSizes(uint8 collection) public view returns (uint256 discount, uint256 redeem, uint256 charm) {
        return (
            traitSizes[collection][1],
            traitSizes[collection][2],
            traitSizes[collection][3]
        );
    }
    
}