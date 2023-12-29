/*
Ark Games Web3 World Interface

Made by: http://koramgame.com (EN)  http://siamgame.in.th (TH)

*/

pragma solidity =0.6.6;

// 
/**
 * @dev Interface of the Game World for Web3 title
 */
interface GameWorld {

    struct World {
        uint weight; 
        bool live; 
        address controller; 
        uint worldId;  
    }

   //extends current contract into second contract (call from 2nd contract) to link functionality for gameworld
    struct ContractExtender { 
        address features_extension;
        bool isExtended;
    }

}

contract GameWorldController_01 {
    
    GameWorld GameInterface;

    int GuildClashVotesTotal;
}