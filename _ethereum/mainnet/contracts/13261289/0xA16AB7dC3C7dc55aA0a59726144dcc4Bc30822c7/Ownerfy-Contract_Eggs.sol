// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
* This contract was deployed by Ownerfy Inc. of Ownerfy.com
*
* EGGS are layed by Chic-A-Dees NFTs 
* Chic-A-Dee NFT Contract 0xB352131fE48571B7661390E65BE4F12119e9686f
* To lay eggs you must be an owner of a Chic-A-Dee
* Then trigger the startOneLaying or harvestEggsFromChic methods
* If a Chic-A-Dee is transferred the last owner can still harvest
* their eggs. If the new owner begins a harvest it will send the 
* last eggs owed to the last owner first. This allows Chic-A-Dees
* to be on sale without worrying about harvesting the eggs
* at the last minute. Legendary Chics lay 2x the eggs.
* There will only be 1 billion eggs total.
* Once legendaries are all set ownership will be renounced.
*
*/
import "./ERC20.sol";
import "./Ownable.sol";

interface ERC1155Interface {
    function balanceOf(address account, uint256 id) external view returns (uint);
}

contract ChicADeeEggs is ERC20, Ownable {
    
    uint256 public constant MAX_EGGS = 1000000000000000000000000000;
    //uint public totalSupply = 0;

    //TODO: this might not take a string
    address public chicContract = 0xB352131fE48571B7661390E65BE4F12119e9686f;

    ERC1155Interface ERC1155Contract = ERC1155Interface(chicContract);

    struct ChicStatus {
      address recipient;
      uint startBlock;
    }
    mapping (uint256 => ChicStatus) public chicStatusMap;
    mapping (uint256 => bool) public isLegendary;


    event StartedLayingEggs(address indexed owner, uint256 indexed id, uint256 blockNumber);
    event HarvestEggs(address indexed recipient, uint256 indexed id, uint256 amount);

    constructor() ERC20("Chic-A-Dee EGGS", "EGGS") {}

    /**
     * @dev Checks `ids` of Chics if they are owned by owner.
     *
     */
    function _ownsChics(uint256[] memory ids) internal virtual returns(bool owns){

        for (uint i = 0; i < ids.length; i++) {

          if(_ownsChic(ids[i]) == false) {
            return false;
          }

        }
        return true;
        
    }

    /**
     * @dev Checks `ids` of Chics if they are owned by owner.
     *
     */
    function _ownsChic(uint256 id) internal virtual returns(bool owns){

        uint256 payload = ERC1155Contract.balanceOf(msg.sender, id);

        if(payload > 0) {
          return true;
        } else {
          return false;
        }

    }

     /**
     * @dev Checks `ids` of Chics if they are owned by owner.
     *
     */
    function _harvestEggs(uint256 id) internal virtual {
        require(totalSupply() < MAX_EGGS, "Max Eggs Reached");
        address lastRecipient = chicStatusMap[id].recipient;
        bool isCurrentOwner = _ownsChic(id);
        require(isCurrentOwner || lastRecipient == msg.sender, "Must be owner or past last");
      
        if(chicStatusMap[id].startBlock == 0) {
          chicStatusMap[id].startBlock = block.number;
        }
        
        uint256 eggsLayed = block.number - chicStatusMap[id].startBlock;

        if(isLegendary[id] == true) {
          eggsLayed = eggsLayed * 2;
        }

        eggsLayed = eggsLayed * 10**18;

        if(isCurrentOwner == false) {
          // If harvest is coming from last owner

          if(eggsLayed > 0) {
            _mint(lastRecipient, eggsLayed);

            emit HarvestEggs(lastRecipient, id, eggsLayed);
          }

          // New owner has to initialize
          // Last owner can't tell who new owner is
          chicStatusMap[id].recipient = address(0);
          
        } else {
          // For current owner

          // If harvest is owner but old owner still has some eggs and hasn't got them
          if(chicStatusMap[id].recipient != msg.sender && chicStatusMap[id].recipient != address(0)) {

            if(eggsLayed > 0) {
              _mint(lastRecipient, eggsLayed);
              emit HarvestEggs(lastRecipient, id, eggsLayed);
            }
            
          } else {
            // If owner is already recipient
            if(eggsLayed > 0) {
              _mint(msg.sender, eggsLayed);
            }
             
            emit HarvestEggs(msg.sender, id, eggsLayed);

          }

          // Set to new owner if it hasn't been
          chicStatusMap[id].recipient = msg.sender;
          
        }

        // Always trigger block reset
        chicStatusMap[id].startBlock = block.number;
        
    }

    // Start laying
    /**
     * @dev Starting to lay `ids`.
     *
     */
    function _startLaying(uint256 id) internal virtual {

      if(chicStatusMap[id].startBlock == 0){
        chicStatusMap[id].startBlock = block.number;
      }

      _harvestEggs(id);

      emit StartedLayingEggs(msg.sender, id, block.number);

    }

    // Start One laying
    /**
     * @dev Starting to lay `ids`.
     *
     */
    function startOneLaying(uint256 id) public virtual {
        // Check that caller owns these IDS
        // Must own to initialize the first time
        require(_ownsChic(id), "Ownerfy: must own this Chic");

        _startLaying(id);

    }

    // Start Many laying
    /**
     * @dev Starting to lay `ids`.
     *
     */
    function startManyLaying(uint256[] memory ids) public virtual {

        // Must own to initialize the first time
        require(_ownsChics(ids), "Ownerfy: must own all these Chics");
        for (uint i = 0; i < ids.length; i++) {
          _startLaying(ids[i]);
        }
    }

    // Harvest Eggs
    /**
     * @dev Harvests list of chics.
     *
     */
    function harvestEggsFromManyChics(uint256[] memory ids) public virtual {

        for (uint i = 0; i < ids.length; i++) {
          _harvestEggs(ids[i]);
        }
    }

    // Harvest Chic
    /**
     * @dev Harvests eggs for 1 chic.
     *
     */
    function harvestEggsFromChic(uint256 id) public virtual {
        _harvestEggs(id);
    }

    // Check chic balance
    /**
     * @dev Check chic balance
     *
     */
    function checkChicBalance(uint256 id) public view returns (uint256 balance){
        if(chicStatusMap[id].startBlock != 0) {
          uint eggsLayed = block.number - chicStatusMap[id].startBlock;
          eggsLayed = eggsLayed * 10**18;
          if(isLegendary[id] == true) {
            eggsLayed = eggsLayed * 2;
          }
          return eggsLayed;
        }
        return 0;   
    }

    // Set Legends
    /**
     * @dev Set Legends.
     *
     */
    function setLegendary(uint256[] memory ids, bool _isLegendary) public virtual onlyOwner{
        for (uint i = 0; i < ids.length; i++) {
          isLegendary[ids[i]] = _isLegendary;
        }
    }

}