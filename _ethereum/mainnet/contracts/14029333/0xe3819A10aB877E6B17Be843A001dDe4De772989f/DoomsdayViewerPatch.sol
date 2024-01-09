//SPDX-License-Identifier: A hedgehog wrote this contract
pragma solidity ^0.8.0;
import "./Doomsday.sol";

contract DoomsdayViewerPatch{

    Doomsday doomsday;

    uint constant IMPACT_BLOCK_INTERVAL = 120;

    int64 constant MAP_WIDTH         = 4320000;   //map units
    int64 constant MAP_HEIGHT        = 2588795;   //map units
    int64 constant BASE_BLAST_RADIUS = 100000;   //map units

    constructor(address _doomsday){
        doomsday = Doomsday(_doomsday);
    }

    function nextImpactIn() public view returns(uint){
        //        uint nextEliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) + IMPACT_BLOCK_INTERVAL - 5 ;

        //goes from  BLOCK - (IMPACT_BLOCK_INTERVAL-1) - 5    to    BLOCK - 5
        uint eliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) - 5;

        return IMPACT_BLOCK_INTERVAL - ((block.number - 5) - eliminationBlock);

        //        return nextEliminationBlock + 5 - block.number;
    }

    function nextImpact() public view returns (int64[2] memory _coordinates, int64 _radius, bytes32 impactId){
        if(nextImpactIn() >= 5){
            return (_coordinates,_radius,impactId);
        }
        //        uint eliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) - 5;

        uint eliminationBlock = (block.number+5) - ((block.number + 5) % IMPACT_BLOCK_INTERVAL) - 5;
        //        uint nextEliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) - 5;
        //        if(eliminationBlock)

        int hash = int(uint(blockhash(eliminationBlock))%uint(type(int).max) );


        //Min radius is half map height divided by num
        int o = MAP_HEIGHT/2/int(doomsday.totalSupply()+1);

        //Limited in smallness to about 8% of map height
        if(o < BASE_BLAST_RADIUS){
            o = BASE_BLAST_RADIUS;
        }
        //Max radius is twice this
        _coordinates[0] = int64(hash%MAP_WIDTH - MAP_WIDTH/2);
        _coordinates[1] = int64((hash/MAP_WIDTH)%MAP_HEIGHT - MAP_HEIGHT/2);
        _radius = int64((hash/MAP_WIDTH/MAP_HEIGHT)%o + o);

        return(_coordinates,_radius, keccak256(abi.encodePacked(_coordinates,_radius)));
    }

    function contractState() public view returns(
        uint totalSupply,
        uint destroyed,
        uint evacuatedFunds,
        Doomsday.Stage stage,
        uint currentPrize,
        bool _isEarlyAccess,
        uint countdown,
        uint _nextImpactIn,
        uint blockNumber
    ){
        stage = doomsday.stage();

        return (
        doomsday.totalSupply(),
        doomsday.destroyed(),
        doomsday.evacuatedFunds(),
        stage,
        doomsday.currentPrize(),
        false,
        0,
        nextImpactIn(),
        block.number
        );
    }
}


// Like the food not the animal