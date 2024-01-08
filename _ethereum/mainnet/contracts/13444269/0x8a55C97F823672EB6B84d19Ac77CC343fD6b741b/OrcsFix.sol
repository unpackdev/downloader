// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

import "./EtherOrcs.sol";

contract EtherTransition  {
    
    address public constant impl = 0x3F04A4960Ef9c509875dF108fc6d27587B8b2723;
    
    address        implementation_;
    address public admin; //Lame requirement from opensea
    uint256 public totalSupply;
    uint256 public oldSupply;
    uint256 public minted;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;
    
    uint256 public constant  cooldown = 10 minutes;
    uint256 public constant  startingTime = 1633951800 + 4.5 hours;

    address public migrator;

    bytes32 internal entropySauce;

    ERC20 public zug;

    mapping (address => bool)     public auth;
    mapping (uint256 => Orc)      public orcs;
    mapping (uint256 => Action)   public activities;
    mapping (Places  => LootPool) public lootPools;
    
    uint256 mintedFromThis = 0;
    bool mintOpen = false;

    MetadataHandlerLike metadaHandler;

    mapping (bytes4 => bool) public unlocked;
    
    struct LootPool { 
        uint8  minLevel; uint8  minLootTier; uint16  cost;   uint16 total;
        uint16 tier_1;   uint16 tier_2;      uint16 tier_3; uint16 tier_4;
    }

    struct Orc { uint8 body; uint8 helm; uint8 mainhand; uint8 offhand; uint16 level; uint16 zugModifier; uint32 lvlProgress; }

    enum   Actions { UNSTAKED, FARMING, TRAINING }
    struct Action  { address owner; uint88 timestamp; Actions action; }

    // These are all the places you can go search for loot
    enum Places { 
        TOWN, DUNGEON, CRYPT, CASTLE, DRAGONS_LAIR, THE_ETHER, 
        TAINTED_KINGDOM, OOZING_DEN, ANCIENT_CHAMBER, ORC_GODS 
    }   
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ActionMade(address owner, uint256 id, uint256 timestamp, uint8 activity);


    function fix(uint256[] calldata ids, uint32[] calldata progresses, uint88[] calldata timestamps) external {
        require(msg.sender == admin);
        uint highesProgress = (block.timestamp - startingTime) * 3000 / 1 days;
        for (uint i = 0; i < ids.length; i++ ) {
            uint256 timeDiff = (block.timestamp - timestamps[i]);
            uint32 progress =  uint32(timeDiff * 3000 / 1 days) + progresses[i];
            orcs[ids[i]].lvlProgress = uint32(progress > highesProgress ? highesProgress : progress);
            orcs[ids[i]].level = uint16(orcs[ids[i]].lvlProgress / 1000);
        }
    }
 

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    

    fallback() external {
        _delegate(impl);
    }
}