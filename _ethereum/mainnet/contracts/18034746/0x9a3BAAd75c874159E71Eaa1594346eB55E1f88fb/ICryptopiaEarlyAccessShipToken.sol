// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./GameEnums.sol";

/// @title Cryptopia EarlyAccessShip Token (EAS)
/// @dev Non-fungible token (ERC721) 
/// @author HFB - <frank@cryptopia.com>
interface ICryptopiaEarlyAccessShipToken {

    /// @dev Returns the amount of different ships
    /// @return count The amount of different ships
    function getShipCount() 
        external view 
        returns (uint);


    /// @dev Retreive a rance of ships
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Ship name (unique)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules the amount of module slots
    /// @return base_speed Ship starting speed (before modules)
    /// @return base_attack Ship starting attack (before modules)
    /// @return base_health Ship starting health (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    /// @return dailyAllocation Daily allocation
    function getShips(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            GameEnums.Rarity[] memory rarity,
            uint24[] memory modules, 
            uint24[] memory base_speed,
            uint24[] memory base_attack,
            uint24[] memory base_health,
            uint24[] memory base_defence,
            uint[] memory base_inventory,
            uint[] memory dailyAllocation
        );


    /// @dev Retreive a ships by name
    /// @param name Ship name (unique)
    /// @return faction {Faction} (can only be equipted by this faction)
    /// @return subFaction {SubFaction} (pirate/bountyhunter)
    /// @return rarity Ship rarity {Rarity}
    /// @return modules the amount of module slots
    /// @return base_speed Ship starting speed (before modules)
    /// @return base_attack Ship starting attack (before modules)
    /// @return base_health Ship starting health (before modules)
    /// @return base_defence Ship starting defence (before modules)
    /// @return base_inventory Ship starting storage (before modules)
    /// @return dailyAllocation Daily allocation
    function getShip(bytes32 name) 
        external view 
        returns (
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction,
            GameEnums.Rarity rarity,
            uint24 modules, 
            uint24 base_speed,
            uint24 base_attack,
            uint24 base_health,
            uint24 base_defence,
            uint base_inventory,
            uint dailyAllocation
        );

    
    /// @dev Retreive ships by token ids
    /// @param tokenIds The ids of the ships to retreive
    /// @return name Ship name (unique)
    /// @return skin Ship skin
    /// @return timestamp timestamp at which the ship was minted
    /// @return totalAllocation The amount of tokens that has been allocated to the ship
    function getShipInstances(uint[] memory tokenIds) 
        external view 
        returns (
            bytes32[] memory name,
            bytes32[] memory skin,
            uint128[] memory timestamp,
            uint[] memory totalAllocation
        );


    /// @dev Mints a ship to an address
    /// @param to address of the owner of the ship
    /// @param tokenId The id of the ship to mint
    /// @param name Unique ship name
    /// @param skinId Ship skin id
    /// @param timestamp timestamp at which the ship was minted
    function mintTo(address to, uint tokenId, bytes32 name, uint128 skinId, uint128 timestamp)  
        external;


    /// @dev Claim allocation
    /// @param tokenId The id of the ship to claim allocation for
    function claim(uint tokenId) 
        external;


    /// @dev Withdraw unclaimed allocation
    function withdraw() 
        external;
}