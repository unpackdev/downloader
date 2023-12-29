// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./IERC20Upgradeable.sol";
import "./IERC1820RegistryUpgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";

import "./GameEnums.sol";
import "./CryptopiaERC721.sol";
import "./ICryptopiaEarlyAccessShipToken.sol";

/// @title CryptopiaEarlyAccessShip Token (EAS)
/// @dev Non-fungible token (ERC721)
/// @author HFB - <frank@cryptopia.com>
contract CryptopiaEarlyAccessShipToken is ICryptopiaEarlyAccessShipToken, CryptopiaERC721, IERC777RecipientUpgradeable {

    /**
     * Structs
     */
    struct Ship
    {
        GameEnums.Faction faction;
        GameEnums.SubFaction subFaction;
        GameEnums.Rarity rarity;
        uint24 modules;
        uint24 base_speed;
        uint24 base_attack;
        uint24 base_health;
        uint24 base_defence;
        uint base_inventory;
        uint dailyAllocation;
    }

    struct ShipInstance
    {
        bytes32 name;
        uint128 skinId;
        uint128 timestamp;
        uint claimed;
    }

    /**
     * Storage
     */
    uint constant public ALLOCATION_END_DATE = 1756684800; // Monday, 1 September 2025 00:00:00
    uint constant public ALLOCATION_WITHDRAWAL_DATE = 1788220800; // Tuesday, 1 September 2026 00:00:00

    address constant private ERC1820_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    bytes32 constant private ERC777_RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");

    /// @dev name => Ship
    mapping(bytes32 => Ship) public ships;
    bytes32[] private shipsIndex;

    /// @dev skinId => skin
    mapping (uint128 => bytes32) public skins;

    /// @dev tokenId => ShipInstance
    mapping (uint => ShipInstance) public shipInstances;

    /// @dev CRT token
    /// @notice Openzeppelin ERC777 token (No need for SafeERC20)
    address public token; 

    /// @dev Beneficiary 
    /// @notice Will receive unclaimed tokens after ALLOCATION_WITHDRAWAL_DATE
    address public beneficiary;

    /**
     * Roles
     */
    bytes32 constant public MINTER_ROLE = keccak256("MINTER_ROLE");


    /**
     * Public functions
     */
    /// @dev Contract initializer sets shared base uri
    /// @param _token The token that is allocated
    /// @param _beneficiary The address that receives the unclaimed tokens after ALLOCATION_WITHDRAWAL_DATE
    /// @param authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address _token,
        address _beneficiary,
        address authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Early-Access Ships", "EAS", authenticator, initialContractURI, initialBaseTokenURI);

        // Refs
        token = _token;
        beneficiary = _beneficiary;

        // Register as ERC777 recipient
        IERC1820RegistryUpgradeable(ERC1820_ADDRESS).setInterfaceImplementer(
            address(this), ERC777_RECIPIENT_INTERFACE, address(this));

        // Common ships
        uint[6] memory stats = [uint(3), 35, 20, 100, 100, 20_000_000_000_000_000_000_000];
        _setShip("Zephyr", GameEnums.Faction.Eco, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Cetus", GameEnums.Faction.Eco, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Common, stats);
        _setShip("Osprey", GameEnums.Faction.Eco, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Common, stats);

        stats = [uint(5), 45, 20, 100, 100, 12_000_000_000_000_000_000_000];
        _setShip("Cygnus", GameEnums.Faction.Tech, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Manta", GameEnums.Faction.Tech, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Common, stats);
        _setShip("Trident", GameEnums.Faction.Tech, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Common, stats);


        stats = [uint(3), 30, 20, 100, 100, 24_000_000_000_000_000_000_000];
        _setShip("Neptune", GameEnums.Faction.Industrial, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Charybdis", GameEnums.Faction.Industrial, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Common, stats);
        _setShip("Maelstrom", GameEnums.Faction.Industrial, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Common, stats);

        stats = [uint(3), 40, 20, 100, 100, 16_000_000_000_000_000_000_000];
        _setShip("Diogenes", GameEnums.Faction.Traditional, GameEnums.SubFaction.None, GameEnums.Rarity.Common, stats);
        _setShip("Tempest", GameEnums.Faction.Traditional, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Common, stats);
        _setShip("Spartacus", GameEnums.Faction.Traditional, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Common, stats);

        // Rare ships
        stats = [uint(3), 38, 20, 110, 110, 20_000_000_000_000_000_000_000];
        _setShip("Zephyr+", GameEnums.Faction.Eco, GameEnums.SubFaction.None, GameEnums.Rarity.Rare, stats);
        _setShip("Cetus+", GameEnums.Faction.Eco, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Rare, stats);
        _setShip("Osprey+", GameEnums.Faction.Eco, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Rare, stats);

        stats = [uint(5), 49, 20, 110, 110, 12_000_000_000_000_000_000_000];
        _setShip("Cygnus+", GameEnums.Faction.Tech, GameEnums.SubFaction.None, GameEnums.Rarity.Rare, stats);
        _setShip("Manta+", GameEnums.Faction.Tech, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Rare, stats);
        _setShip("Trident+", GameEnums.Faction.Tech, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Rare, stats);

        stats = [uint(3), 33, 20, 110, 110, 24_000_000_000_000_000_000_000];
        _setShip("Neptune+", GameEnums.Faction.Industrial, GameEnums.SubFaction.None, GameEnums.Rarity.Rare, stats);
        _setShip("Charybdis+", GameEnums.Faction.Industrial, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Rare, stats);
        _setShip("Maelstrom+", GameEnums.Faction.Industrial, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Rare, stats);

        stats = [uint(3), 44, 20, 110, 110, 16_000_000_000_000_000_000_000];
        _setShip("Diogenes+", GameEnums.Faction.Traditional, GameEnums.SubFaction.None, GameEnums.Rarity.Rare, stats);
        _setShip("Tempest+", GameEnums.Faction.Traditional, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Rare, stats);
        _setShip("Spartacus+", GameEnums.Faction.Traditional, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Rare, stats);

        // Legendary ships
        stats = [uint(3), 41, 20, 150, 150, 20_000_000_000_000_000_000_000];
        _setShip("Zephyr++", GameEnums.Faction.Eco, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Cetus++", GameEnums.Faction.Eco, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Legendary, stats);
        _setShip("Osprey++", GameEnums.Faction.Eco, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Legendary, stats);

        stats = [uint(5), 53, 20, 150, 150, 12_000_000_000_000_000_000_000];
        _setShip("Cygnus++", GameEnums.Faction.Tech, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Manta++", GameEnums.Faction.Tech, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Legendary, stats);
        _setShip("Trident++", GameEnums.Faction.Tech, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Legendary, stats);

        stats = [uint(3), 36, 20, 150, 150, 24_000_000_000_000_000_000_000];
        _setShip("Neptune++", GameEnums.Faction.Industrial, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Charybdis++", GameEnums.Faction.Industrial, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Legendary, stats);
        _setShip("Maelstrom++", GameEnums.Faction.Industrial, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Legendary, stats);

        stats = [uint(3), 48, 20, 150, 150, 16_000_000_000_000_000_000_000];
        _setShip("Diogenes++", GameEnums.Faction.Traditional, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Tempest++", GameEnums.Faction.Traditional, GameEnums.SubFaction.Pirate, GameEnums.Rarity.Legendary, stats);
        _setShip("Spartacus++", GameEnums.Faction.Traditional, GameEnums.SubFaction.BountyHunter, GameEnums.Rarity.Legendary, stats);
    
        // Special ships
        stats = [uint(8), 50, 20, 150, 150, 40_000_000_000_000_000_000_000];
        _setShip("Olympus++", GameEnums.Faction.Eco, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Charlemagne++", GameEnums.Faction.Tech, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Titan++", GameEnums.Faction.Industrial, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);
        _setShip("Poseidon++", GameEnums.Faction.Traditional, GameEnums.SubFaction.None, GameEnums.Rarity.Legendary, stats);

        // Set skins
        skins[0] = "Default";
    }


    /// @dev Set ship skins
    /// @param skinIds Skin ids
    /// @param skinNames Skin names
    function setSkins(uint128[] memory skinIds, bytes32[] memory skinNames) 
        public virtual 
        onlyRole(ADMIN_ROLE) 
    {
        for (uint i = 0; i < skinIds.length; i++)
        {
            skins[skinIds[i]] = skinNames[i];
        }
    }


    /// @dev Returns the amount of different ships
    /// @return count The amount of different ships
    function getShipCount() 
        public virtual override view 
        returns (uint)
    {
        return shipsIndex.length;
    }


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
        public override view 
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
        )
    {
        name = new bytes32[](take);
        faction = new GameEnums.Faction[](take);
        subFaction = new GameEnums.SubFaction[](take);
        rarity = new GameEnums.Rarity[](take);
        modules = new uint24[](take);
        base_speed = new uint24[](take);
        base_attack = new uint24[](take);
        base_health = new uint24[](take);
        base_defence = new uint24[](take);
        base_inventory = new uint[](take);
        dailyAllocation = new uint[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            name[i] = shipsIndex[index];
            faction[i] = ships[name[i]].faction;
            subFaction[i] = ships[name[i]].subFaction;
            rarity[i] = ships[name[i]].rarity;
            modules[i] = ships[name[i]].modules;
            base_speed[i] = ships[name[i]].base_speed;
            base_attack[i] = ships[name[i]].base_attack;
            base_health[i] = ships[name[i]].base_health;
            base_defence[i] = ships[name[i]].base_defence;
            base_inventory[i] = ships[name[i]].base_inventory;
            dailyAllocation[i] = ships[name[i]].dailyAllocation;
            index++;
        }
    }


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
        public virtual override view 
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
        )
    {
        faction = ships[name].faction;
        subFaction = ships[name].subFaction;
        rarity = ships[name].rarity;
        modules = ships[name].modules;
        base_speed = ships[name].base_speed;
        base_attack = ships[name].base_attack;
        base_health = ships[name].base_health;
        base_defence = ships[name].base_defence;
        base_inventory = ships[name].base_inventory;
        dailyAllocation = ships[name].dailyAllocation;
    }


    /// @dev Retreive ships by token ids
    /// @param tokenIds The ids of the ships to retreive
    /// @return name Ship name (unique)
    /// @return skin Ship skin
    /// @return timestamp timestamp at which the ship was minted
    /// @return totalAllocation The amount of tokens that has been allocated to the ship
    function getShipInstances(uint[] memory tokenIds) 
        public virtual override view 
        returns (
            bytes32[] memory name,
            bytes32[] memory skin,
            uint128[] memory timestamp,
            uint[] memory totalAllocation
        )
    {
        name = new bytes32[](tokenIds.length);
        skin = new bytes32[](tokenIds.length);
        timestamp = new uint128[](tokenIds.length);
        totalAllocation = new uint[](tokenIds.length);

        for (uint i = 0; i < tokenIds.length; i++)
        {
            name[i] = shipInstances[tokenIds[i]].name;
            skin[i] = skins[shipInstances[tokenIds[i]].skinId];
            timestamp[i] = shipInstances[tokenIds[i]].timestamp;
            totalAllocation[i] = _getTotalAllocation(tokenIds[i]);
        }
    }


    /// @dev Mints a ship to an address
    /// @param to address of the owner of the ship
    /// @param tokenId The id of the ship to mint
    /// @param name Unique ship name
    /// @param skinId Ship skin id
    /// @param timestamp timestamp at which the ship was minted
    function mintTo(address to, uint tokenId, bytes32 name, uint128 skinId, uint128 timestamp)  
        public virtual override 
        onlyRole(MINTER_ROLE)  
    {
        _safeMint(to, tokenId);
        shipInstances[tokenId].name = name;
        shipInstances[tokenId].skinId = skinId;
        shipInstances[tokenId].timestamp = timestamp;
    }


    /// @dev Claim allocation
    /// @param tokenId The id of the ship to claim allocation for
    function claim(uint tokenId) 
        public virtual override 
    {
        require(_canClaim(), "Unable to claim");
        require(_msgSender() == ownerOf(tokenId), "Not owner of token");

        uint totalAllocation = _getTotalAllocation(tokenId);
        require(totalAllocation > 0, "No allocation");
        
        // Mark claimed
        shipInstances[tokenId].claimed += totalAllocation;

        // Transfer allocation
        require(
            IERC20Upgradeable(token)
                .transfer(_msgSender(), totalAllocation), 
            "Claim failed"
        );
    }


    /// @dev Withdraw unclaimed allocation 
    function withdraw() 
        public virtual override 
    {
        require(block.timestamp >= ALLOCATION_WITHDRAWAL_DATE, "Unable to withdraw");
        require(_msgSender() == beneficiary, "Not beneficiary");

        // Transfer allocation
        require(
            IERC20Upgradeable(token)
                .transfer(
                    beneficiary, 
                    IERC20Upgradeable(token)
                        .balanceOf(address(this))), 
            "Withdraw failed"
        );
    }


    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) public virtual override 
    {
        // Nothing for now
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that might have been send there by accident
    /// Note: Access control check happens in super
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(IERC20Upgradeable tokenContract) 
        public virtual override 
    {
        require(address(tokenContract) != token, "Use withdraw");
        super.retrieveTokens(tokenContract);
    }


    /**
     * Private functions
     */
    /// @dev True if a ship with `name` exists
    /// @param name of the ship
    function _exists(bytes32 name) 
        internal view 
        returns (bool) 
    {
        return ships[name].base_speed != 0;
    }


    /// @dev Add or update ships
    /// @param name Ship name (unique)
    /// @param faction {Faction} (can only be equipted by this faction)
    /// @param subFaction {SubFaction} (pirate/bountyhunter)
    /// @param rarity Ship rarity {Rarity}
    /// @param stats modules, arbitrary, base_speed, base_attack, base_health, base_defence, base_inventory
    function _setShip(
        bytes32 name, 
        GameEnums.Faction faction, 
        GameEnums.SubFaction subFaction, 
        GameEnums.Rarity rarity, 
        uint[6] memory stats) 
        internal 
    {
        // Add ship
        if (!_exists(name))
        {
            shipsIndex.push(name);
        }

        // Set ship
        ships[name].faction = faction;
        ships[name].subFaction = subFaction;
        ships[name].rarity = rarity;
        ships[name].modules = uint24(stats[0]);
        ships[name].base_speed = uint24(stats[1]);
        ships[name].base_attack = uint24(stats[2]);
        ships[name].base_health = uint24(stats[3]);
        ships[name].base_defence = uint24(stats[4]);
        ships[name].base_inventory = stats[5];
        ships[name].dailyAllocation = rarity == GameEnums.Rarity.Common ? 50_000_000_000_000_000_000 : 
            rarity == GameEnums.Rarity.Rare ? 80_000_000_000_000_000_000 : 250_000_000_000_000_000_000;
    }


    /// @dev True if allocation can be claimed
    /// @return bool True if allocation can be claimed
    function _canClaim() 
        internal view 
        returns (bool) 
    {
        return block.timestamp >= ALLOCATION_END_DATE;
    }


    /// @dev Retreive total allocation for a ship
    /// @param tokenId The id of the ship to retreive the allocation for
    /// @return uint The amount that has been allocated to the ship
    function _getTotalAllocation(uint tokenId) 
        internal view 
        returns (uint) 
    {
        if (shipInstances[tokenId].timestamp > block.timestamp)
        {
            return 0;
        }   

        // daily allocation * days since mint - claimed
        return (ships[shipInstances[tokenId].name].dailyAllocation 
            * (((block.timestamp > ALLOCATION_END_DATE ? ALLOCATION_END_DATE : block.timestamp) - shipInstances[tokenId].timestamp) / 1 days)
        ) - shipInstances[tokenId].claimed;
    }
}