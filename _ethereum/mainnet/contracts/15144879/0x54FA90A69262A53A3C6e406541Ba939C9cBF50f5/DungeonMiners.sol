//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "./Attempt.sol";
import "./Class.sol";
import "./Miner.sol";
import "./Item.sol";
import "./Calcs.sol";
import "./Counters.sol";
import "./Metadata.sol";

/*

     /@@@@@@@  /@@   /@@ /@@   /@@  /@@@@@@  /@@@@@@@@  /@@@@@@  /@@   /@@
    | @@__  @@| @@  | @@| @@@ | @@ /@@__  @@| @@_____/ /@@__  @@| @@@ | @@
    | @@  \ @@| @@  | @@| @@@@| @@| @@  \__/| @@      | @@  \ @@| @@@@| @@
    | @@  | @@| @@  | @@| @@ @@ @@| @@ /@@@@| @@@@@   | @@  | @@| @@ @@ @@
    | @@  | @@| @@  | @@| @@  @@@@| @@|_  @@| @@__/   | @@  | @@| @@  @@@@
    | @@  | @@| @@  | @@| @@\  @@@| @@  \ @@| @@      | @@  | @@| @@\  @@@
    | @@@@@@@/|  @@@@@@/| @@ \  @@|  @@@@@@/| @@@@@@@@|  @@@@@@/| @@ \  @@
    |_______/  \______/ |__/  \__/ \______/ |________/ \______/ |__/  \__/

        /@@      /@@ /@@@@@@ /@@   /@@ /@@@@@@@@ /@@@@@@@   /@@@@@@
        | @@@    /@@@|_  @@_/| @@@ | @@| @@_____/| @@__  @@ /@@__  @@
        | @@@@  /@@@@  | @@  | @@@@| @@| @@      | @@  \ @@| @@  \__/
        | @@ @@/@@ @@  | @@  | @@ @@ @@| @@@@@   | @@@@@@@/|  @@@@@@
        | @@  @@@| @@  | @@  | @@  @@@@| @@__/   | @@__  @@ \____  @@
        | @@\  @ | @@  | @@  | @@\  @@@| @@      | @@  \ @@ /@@  \ @@
        | @@ \/  | @@ /@@@@@@| @@ \  @@| @@@@@@@@| @@  | @@|  @@@@@@/
        |__/     |__/|______/|__/  \__/|________/|__/  |__/ \______/
    
*/

contract DungeonMiners {
    using Strings for *;
    using Counters for Counters.Counter;

    /**
    *
    *  DUNGEON MINER CUSTOM VARS
    *
    */

    // Address of the creator of the contract
    address CREATOR;

    // Address of the treasury contract
    address payable TREASURY;

    // The current supply
    Counters.Counter private TOKEN_SUPPLY;

    // Token id of the most recent token to redeem the prize pool
    uint256 private LAST_WITHDRAWN = 0;

    // Configure floating difficulty target to make it harder for people to hunt for difficulty solutions in advance
    // Set initial difficulty target as middle of potential hash value range
    uint256 private DIFFICULTY_TARGET = uint256(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    // Difficulty target range is 0x00000033216c94739703b2e9ffd940abb780678f326aac1d5cfddef0b1857bcb

    // Difficulty radius is half of difficulty target range
    uint256 private DIFFICULTY_RADIUS = uint256(0x0000001990b64a39cb81d974ffeca055dbc033c79935560eae7eef7858c2bde5);

    // Difficulty limit is the potential hash value range minus the difficulty target range
    uint256 private DIFFICULTY_LIMIT = uint256(0xffffffccde936b8c68fc4d160026bf54487f9870cd9553e2a302210f4e7a8434);
    
    // Array of character classes
    Class[4] public CLASSES;

    // Array of shop items
    Item[8] public SHOP_ITEMS;

    /**
    *
    *  DUNGEON MINER EVENTS
    *
    */

    // Let the world know that a token has been mined
    event Mined(uint256 indexed tokenId, address indexed minter, bytes32 indexed hash, uint256 startTokenId, uint256 difficultyTarget, uint256 difficultyRadius, uint256 itemId, uint256 classId, uint256 genderId);

    // Let the world know that ETH from the prize pool has been redeemed
    event Redeemed(uint256 indexed tokenId, address indexed primaryWinner, uint256 payout, address indexed secondaryWinner, uint256 secondaryPayout);

    // Let the world know that an attempt has been started
    event AttemptStarted(uint256 indexed tokenId, uint256 indexed startTokenId);

    /**
    *
    *  ERC-721 EVENTS
    *
    */

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
    *
    *  ERC-721 VARS
    *
    */

    // Mapping of tokens
    mapping(uint256 => Attempt) TOKENS;

    // Mapping of owners
    mapping(uint256 => address) OWNERS;

    // How many tokens a particular address owns
    mapping(address => uint256) internal BALANCES;

    // Addresses allowed to manage specific tokens
    mapping(uint256 => address) internal ALLOWANCE;

    // Addresses allowed to control all assets of other addresses in this smart contract
    mapping(address => mapping(address => bool)) internal AUTHORIZED;


    /**
    *
    *  ERC-165 VARS
    *
    */

    // Map of supported interfaces
    mapping (bytes4 => bool) internal supportedInterfaces;

    /**
    *
    *  CONSTRUCTOR
    *
    */

    /**
    * @notice construct function
    * @param treasuryAddress the address of the treasury contract
    */
    constructor(address treasuryAddress)
        payable
    {
        // Ensure that the contract has been seeded with enough ETH to cover 50 mints
        require(msg.value == 3 ether);

        // Define supported interfaces
        supportedInterfaces[0x80ac58cd] = true; // ERC-721
        supportedInterfaces[0x5b5e139f] = true; // ERC-721 Metadata
        supportedInterfaces[0x01ffc9a7] = true; // ERC-165

        // Define creator of contract
        CREATOR = address(0x79ac53F63728684F5B21B6302FC5Cef5A8E8b7e9);

        // Define treasury address
        TREASURY = payable(treasuryAddress);

        // Define classes
        CLASSES[0] = Class({baseHealth: 200, baseArmor: 75, baseAttack: 40, baseSpeed: 40});    // 0 | Warrior
        CLASSES[1] = Class({baseHealth: 195, baseArmor: 85, baseAttack: 35, baseSpeed: 40});    // 1 | Mage
        CLASSES[2] = Class({baseHealth: 175, baseArmor: 80, baseAttack: 35, baseSpeed: 50});    // 2 | Ranger
        CLASSES[3] = Class({baseHealth: 225, baseArmor: 90, baseAttack: 30, baseSpeed: 50});    // 3 | Assassin

        // Define shop items
        SHOP_ITEMS[0] = Item({cost: 0, healthMod: 0, armorMod: 0, attackMod: 0, speedMod: 0});                 // 0 | No Item
        SHOP_ITEMS[1] = Item({cost: 0.005 ether, healthMod: 15, armorMod: 0, attackMod: 0, speedMod: 0});      // 1 | Health Potion
        SHOP_ITEMS[2] = Item({cost: 0.005 ether, healthMod: 0, armorMod: 15, attackMod: 0, speedMod: 0});      // 2 | Simple Bracers
        SHOP_ITEMS[3] = Item({cost: 0.005 ether, healthMod: 0, armorMod: 0, attackMod: 10, speedMod: 0});      // 3 | Strength Potion
        SHOP_ITEMS[4] = Item({cost: 0.005 ether, healthMod: 0, armorMod: 0, attackMod: 0, speedMod: 10});      // 4 | Strong Coffee
        SHOP_ITEMS[5] = Item({cost: 0.0075 ether, healthMod: 15, armorMod: 0, attackMod: 0, speedMod: 10});    // 5 | Cooked Dinner
        SHOP_ITEMS[6] = Item({cost: 0.0075 ether, healthMod: 0, armorMod: 15, attackMod: 10, speedMod: 0});    // 6 | Soldier Training
        SHOP_ITEMS[7] = Item({cost: 0.01 ether, healthMod: 15, armorMod: 15, attackMod: 10, speedMod: 10});    // 7 | Ancient Blessing

        // Mint 50 inactive Miners for drops, rewards, etc.
        for(uint8 i = 0; i < 50; i++){

            // Increase TOKEN_SUPPLY by one
            TOKEN_SUPPLY.increment();

            // Generate and define token hash
            bytes32 hash = keccak256(abi.encodePacked(
                CREATOR,
                i,
                (i == 0 ? bytes32(0) : TOKENS[i].hash),
                block.timestamp
            ));

            // Define alternating gender id
            uint256 genderId = (i % 2);

            // Define class id
            uint256 classId = (uint256(hash) % 4);

            // Mint the token with the token ID and new hash with rotating class/gender
            _mint(TOKEN_SUPPLY.current(),hash,uint256(hash),0,0,classId,genderId);

            // Let the world know
            emit Mined(TOKEN_SUPPLY.current(),msg.sender,hash,0,DIFFICULTY_TARGET,DIFFICULTY_RADIUS,0,classId,genderId);
        }
    }

    /**
    *
    *  METADATA METHODS
    *
    */

    /**
    * @notice return the starting stats for a miner
    * @param attempt the escape attempt struct
    * @return array of the miner as it entered the dungeon (struct -> array)
    */
    function _getStartingMiner(Attempt memory attempt)
        internal
        view
        returns(Miner memory)
    {
        // Get class data from storage for provided class id
        Class memory class = CLASSES[attempt.classId];

        // Get starting item data from storage for provided item id
        Item memory item = SHOP_ITEMS[attempt.itemId];
        
        // Define the miner and its base stats
        Miner memory miner = Miner({
            baseHealth: int16(uint16((uint8(attempt.hash[0]) % 48))) + class.baseHealth + item.healthMod,
            baseArmor: int16(uint16((uint8(attempt.hash[1]) % 24))) + class.baseArmor + item.armorMod,
            health: 0,
            armor: 0,
            attack: int16(uint16((uint8(attempt.hash[2]) % 24))) + class.baseAttack + item.attackMod,
            speed: int16(uint16((uint8(attempt.hash[3]) % 24))) + class.baseSpeed + item.speedMod,
            genderId: attempt.genderId,
            classId: attempt.classId,
            skintoneId: uint8(attempt.hash[21]) < 250 ? (uint8(attempt.hash[21]) % 10) : ((uint8(attempt.hash[21]) % 6) + 10),
            hairColorId: uint8(attempt.hash[27]) % 8,
            hairTypeId: uint8(attempt.hash[26]) % 8,
            eyeColorId: (uint8(attempt.hash[23]) < 252 ? (uint8(attempt.hash[23]) % 9) : ((uint8(attempt.hash[23]) % 4) + 9)),
            eyeTypeId: uint8(attempt.hash[24]) % 4,
            mouthId: uint8(attempt.hash[25]) % 8,
            headgearId: (Calcs.gType(uint8(attempt.hash[16])) > 8 ? uint8(((Calcs.gType(uint8(attempt.hash[16])) - 9) * 4) + 9 + attempt.classId) : Calcs.gType(uint8(attempt.hash[16]))),
            armorId: (Calcs.gType(uint8(attempt.hash[17])) > 8 ? uint8(((Calcs.gType(uint8(attempt.hash[17])) - 9) * 4) + 9 + attempt.classId) : Calcs.gType(uint8(attempt.hash[17]))) + 17,
            pantsId: (Calcs.gType(uint8(attempt.hash[18])) > 8 ? uint8(((Calcs.gType(uint8(attempt.hash[18])) - 9) * 4) + 9 + attempt.classId) : Calcs.gType(uint8(attempt.hash[18]))) + 34,
            footwearId: (Calcs.gType(uint8(attempt.hash[19])) > 8 ? uint8(((Calcs.gType(uint8(attempt.hash[19])) - 9) * 4) + 9 + attempt.classId) : Calcs.gType(uint8(attempt.hash[19]))) + 51,
            weaponId: (Calcs.gType(uint8(attempt.hash[20])) > 4 ? uint8(((Calcs.gType(uint8(attempt.hash[20])) - 5) * 4) + 5 + attempt.classId) : Calcs.gType(uint8(attempt.hash[20]))) + 68,
            gold: 0,
            curseTurns: 0,
            buffTurns: 0,
            debuffTurns: 0,
            revives: 0,
            currentChamber: 0
        });

        // Define empty gearItem
        int16[6] memory gearItem;

        // Loop through gear types
        for(uint256 i = 0; i < 5; i++){
            if(i == 0){
                gearItem = Calcs.headgearStats(miner.headgearId);
            } else if(i == 1){
                gearItem = Calcs.armorStats(miner.armorId);
            } else if(i == 2){
                gearItem = Calcs.pantsStats(miner.pantsId);
            } else if(i == 3){
                gearItem = Calcs.footwearStats(miner.footwearId);
            } else if(i == 4){
                gearItem = Calcs.weaponStats(miner.weaponId);
            }
            // Add gear health buff to baseHealth
            miner.baseHealth = miner.baseHealth + gearItem[0];
            // Add gear armor buff to baseArmor
            miner.baseArmor = miner.baseArmor + gearItem[1];
            // Add gear attack buff to attack
            miner.attack = miner.attack + gearItem[2];
            // Add gear speed buff to speed
            miner.speed = miner.speed + gearItem[3];
        }
        // Set current miner health to base health
        miner.health = miner.baseHealth;
        // Set current miner armor to base armor
        miner.armor = miner.baseArmor;

        // Return the miner
        return miner;
    }

    /**
    * @notice return the stats for a miner given a chamber number
    * @param tokenId the token id of the miner
    * @param chamberCount how many chambers to return
    * @return array of the miner in its current state (struct -> array)
    */
    function getMiner(uint256 tokenId, uint8 chamberCount)
        public
        view
        returns (Miner memory)
    {
        // Ensure that the token id has been minted
        require(_isValidToken(tokenId),'invalid token');

        // Get the starting attempt data for this token from storage
        Attempt memory attempt = TOKENS[tokenId];

        // Get all potential chamber hashes for this token
        bytes32[47] memory chambers = _getChambers(tokenId,attempt.startTokenId);

        // Define the starting miner struct
        Miner memory miner = _getStartingMiner(attempt);

        // Set the miner's current chamber to 1 to skip calculating the spawn chamber
        miner.currentChamber = 1;

        // Loop through all chambers and calculate attempt data as long as it's < chamber 46, miner is alive and chamber hash is not empty
        while(miner.currentChamber < 46 && miner.currentChamber <= chamberCount && miner.health > 0 && chambers[miner.currentChamber] != bytes32(0)){
            // Calculate and return the miner and stats after traversing this chamber
            miner = Calcs.chamberStats(keccak256(abi.encodePacked(chambers[0],chambers[miner.currentChamber])),miner);
            miner.currentChamber++;
        }
        return miner;
    }

    /**
    * @notice overload getMiner function to default to the current state of the miner
    * @param tokenId the token id of the miner
    * @return array of the miner in its current state (struct -> array)
    */
    function getMiner(uint256 tokenId)
        public
        view
        returns (Miner memory)
    {
        return getMiner(tokenId,46);
    }

    /**
    * @notice return all potential chambers for a given miner
    * @param tokenId the token id of the miner
    * @param startTokenId the starting token id of the miner
    * @return array of chamber hashes
    */
    function _getChambers(uint256 tokenId, uint256 startTokenId)
        internal
        view
        returns(bytes32[47] memory)
    {
        // Define array of hashes
        bytes32[47] memory hashes;

        // Set the first chamber as the mint chamber
        hashes[0] = TOKENS[tokenId].hash;

        // Loop through potential token ids starting from the start token id
        if(startTokenId != 0){
            for(uint256 i = 1; i < 47; i++){
                // Add hash value to hashes array. If the token is not valid, set the hash value to zero
                hashes[i] = TOKENS[startTokenId + i].hash;
                if(hashes[i] == bytes32(0)){
                    break;
                }
            }
        }
        
        return hashes;
    }

    /**
    * @notice generate and return the data for a miner
    * @param tokenId the token id of the miner
    * @return string representing a data uri
    */
    function _tokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        // Get the json attributes and image data for a given token id
        (string memory attributes, string memory imageData) = _getData(tokenId);

        // Pack the metadata together in data URI format
        string memory metadata = string(abi.encodePacked(
            'data:text/plain,{"name":"Miner %23',
            tokenId.toString(),
            '","description":"An escape attempt through the dark dungeon.","attributes":[',
            attributes,
            '],"image":"',
            imageData,
            '"}'
        ));
        // Return the metadata
        return metadata;
    }

    /**
    * @notice return json attribute data and image data URI for a miner
    * @param tokenId the token id of the miner
    * @return array of strings representing json attribute data and image data URI for a miner
    */
    function _getData(uint256 tokenId)
        internal
        view
        returns (string memory,string memory)
    {
        // Get the starting attempt data for this token from storage
        Attempt memory attempt = TOKENS[tokenId];

        // Get the miner for this attempt
        Miner memory miner = _getStartingMiner(attempt);
        
        // Get chambers
        bytes32[47] memory chambers = _getChambers(tokenId,attempt.startTokenId);
        
        // Return the data
        return Metadata.build(attempt,miner,chambers);
    }

    /**
    * @notice return whether or not an address can redeem from the prize pool for a given token id
    * @param owner the address of the owner
    * @param tokenId the token id of the miner
    * @return boolean representing whether or not the token can be redeemed at this time
    */
    function canRedeem(address owner, uint256 tokenId)
        public
        view
        returns (bool)
    {
        // Ensure that the tokenId has been minted
        require(_isValidToken(tokenId),'invalid token');

        // Ensure that the supplied address owns the held token being withdrawn from
        require(ownerOf(tokenId) == owner,"owner");

        // Get the starting attempt data for this token from storage
        Attempt memory attempt = TOKENS[tokenId];

        // Ensure that a token with a matching or higher id has not redeemed the prize pool already 
        require(LAST_WITHDRAWN < attempt.startTokenId,"previously redeemed");

        // Ensure that an attempt has started
        require(attempt.startTokenId > 0,"preparing");

        // Get all potential chamber hashes for this token
        bytes32[47] memory chambers = _getChambers(tokenId,attempt.startTokenId);

        // Define the starting miner struct
        Miner memory miner = _getStartingMiner(attempt);

        // Set the miner's current chamber to 1 to skip calculating the spawn chamber
        miner.currentChamber = 1;

        // Loop through all chambers and calculate attempt data as long as it's < chamber 47, miner is alive and chamber hash is not empty
        while(miner.currentChamber < 46 && miner.health > 0 && chambers[miner.currentChamber] != bytes32(0)){
            // Calculate and return the miner and stats after traversing this chamber
            miner = Calcs.chamberStats(keccak256(abi.encodePacked(chambers[0],chambers[miner.currentChamber])),miner);
            miner.currentChamber++;
        }

        // Check if a miner is still alive and has cleared all chambers to reach the exit (46)
        if(miner.health > 0 && miner.currentChamber == 46){
            // Token can be redeemed! Return true
            return true;
        }
        // Nope, return false
        return false;
    }

    /**
    * @notice return the total supply of tokens
    * @return uint256 value of the total supply of tokens
    */
    function totalSupply()
        external
        view
        returns(uint256)
    {
        // Return count of tokens counter
        return TOKEN_SUPPLY.current();
    }

    /**
    * @notice return the total prize pool value
    * @return uint256 value of the balance of the prize pool
    */
    function poolValue()
        external
        view
        returns(uint256)
    {
        // Return balance of prize pool in contract
        return address(this).balance;
    }

    /**
    * @notice return the potential redeemable value from the prize pool for a token id
    * @param tokenId the token id of the miner
    * @return uint256 value of the amount that will be eligible to be redeemed from the contract for the provided token upon escape
    */
    function redeemableValue(uint256 tokenId)
        public
        view
        returns(uint256)
    {
        // Get the starting attempt data for this token from storage
        Attempt memory attempt = TOKENS[tokenId];

        // Check if anyone has redeemed the prize pool yet
        if(LAST_WITHDRAWN == 0){
            // First redemption! Add 46 to the token id to account for the chambers traversed to reach the exit
            return (attempt.startTokenId + 46) * 0.06 ether;

        } else if(LAST_WITHDRAWN < tokenId){
            // Not the first redemption and the provided token id is higher than the last withdrawn token id, subtract the current token id from the last withdrawn token id to calculate how much ETH can be withdrawn for the given token
            return (attempt.startTokenId - LAST_WITHDRAWN) * 0.06 ether;
        }

        // Not the first redemption but the last withdrawn token id is equal to or more than the provided token id, so no ETH can be withdrawn
        return 0;
    }

    /**
    * @notice withdraw winnings from the prize pool
    * @param tokenId the token id of the escaped miner
    * @return boolean representing whether or not the prize was redeemed
    */
    function redeem(uint256 tokenId)
        external
        returns(bool)
    {
        // Ensure that the tx sender can redeem the prize pool with the provided token id
        require(canRedeem(msg.sender, tokenId),"cannot redeem");

        // Get the starting attempt data for this token
        Attempt memory attempt = TOKENS[tokenId];

        // Define the total payout available to this token id
        uint256 payout = redeemableValue(tokenId);

        // Check if the payout available is greater than 0
        if(payout > 0){
            // Redeemable ETH available from prize pool!

            // Define secondary payout (1/10 of payout)
            uint256 secondaryPayout = payout / 10;

            // Remove secondary payout from payout amount
            payout  = payout - secondaryPayout;

            // Define total supply
            uint256 supply = TOKEN_SUPPLY.current();

            // Define empty secondary winner
            address secondaryWinner;

            // Select a secondary winner
            uint256 secondaryWinnerTokenId = uint256(keccak256(abi.encodePacked(
                tokenId,
                payout
            ))) % supply;
            secondaryWinner = ownerOf(secondaryWinnerTokenId);

            // Set last withdrawn token id to the provided token's starting chamber id
            LAST_WITHDRAWN = attempt.startTokenId;

            // Send payout amount to tx sender
            payable(msg.sender).transfer(payout);

            // Send secondaryPayout amount to secondary winner
            payable(secondaryWinner).transfer(secondaryPayout);

            // Let the world know that the prize pool has been redeemed
            emit Redeemed(tokenId,msg.sender,payout,secondaryWinner,secondaryPayout);

            // Prize redeemed, return success
            return true;
        }

        // No available funds, revert
        revert("no funds");
        
    }

    /**
    * @notice start an escape attempt if the miner has not yet entered the dungeon
    * @param tokenId the token id of the pending miner
    * @return uint256 value of the starting token id
    */
    function startAttempt(uint256 tokenId)
        external
        returns(uint256)
    {
        // Ensure the sender owns the token
        require(ownerOf(tokenId) == msg.sender,"owner");

        // Ensure this attempt has not yet started
        Attempt memory attempt = TOKENS[tokenId];
        require(attempt.startTokenId == 0,"started");

        // Get total supply (this the most recent tokenId and will be the startTokenId)
        uint256 supply = TOKEN_SUPPLY.current();

        // Set new value in struct and save to contract
        attempt.startTokenId = supply;
        TOKENS[tokenId] = attempt;

        // Let the world know
        emit AttemptStarted(tokenId,supply);

        // Return the starting token id
        return supply;
    }

    /**
    *
    *  MINING & MINTING METHODS
    *
    */

    /**
    * @notice return the current difficulty variables
    * @return array of the the current difficulty variables
    */
    function getDifficulty()
        external
        view
        returns(uint256, uint256)
    {
        // Return difficulty variables (target and radius)
        return (DIFFICULTY_TARGET,DIFFICULTY_RADIUS);
    }
    
    /**
    * @notice mine a token and mint it if the difficulty target problem has been solved
    * @param nonce the nonce solving the difficulty target problem for the message sender
    * @param itemId the item id of the miner's starting item
    * @param classId the class id of the miner
    * @param genderId the gender id of the miner
    * @param startNow whether or not the miner should enter the dungeon right away
    */
    function mine(uint256 nonce, uint256 itemId, uint256 classId, uint256 genderId, bool startNow)
        payable
        public
    {
        // Ensure the class is valid
        require(classId < 4,"class");

        // Ensure the item is valid
        require(itemId < 8,"item");

        // Ensure the gender is valid
        require(genderId < 2,"gender");

        // Ensure the transaction contains enough ETH to mint
        require(msg.value >= (0.08 ether + SHOP_ITEMS[itemId].cost), "cost");

        // Get current supply
        uint256 supply = TOKEN_SUPPLY.current();

        // Get next token id
        uint256 tokenId = supply + 1;

        // Define hash var
        bytes32 hash;

        // Check if this is the first token to be minted
        if(supply > 0){
            // Not first token
            hash = keccak256(abi.encodePacked(
                msg.sender,
                TOKENS[supply].hash,
                nonce
            ));
        } else {
        // First token
            hash = keccak256(abi.encodePacked(
                msg.sender,
                bytes32(0x0000000000000000000000000000000000000000000000000000000000000000),
                nonce
            ));
        }

        // Make sure the difficulty target problem has been solved
        require(uint256(hash) >= (DIFFICULTY_TARGET - DIFFICULTY_RADIUS) && uint256(hash) < (DIFFICULTY_TARGET + DIFFICULTY_RADIUS), "range");

        // Create new hash to commit to blockchain by rehashing the calculated difficulty hash with the Miner's itemId, classId, genderId, the timestamp of the current block, the current coinbase, block difficulty and block number
        hash = keccak256(abi.encodePacked(hash,itemId,classId,genderId,block.timestamp,block.coinbase,block.difficulty,block.number));

        // Store 0.06 of the base cost in the contract/prize pot and send the remainder to the treasury
        (bool sent, bytes memory data) = TREASURY.call{value: msg.value - 0.06 ether}("");
        require(sent, "payment");

        // Increase TOKEN_SUPPLY
        TOKEN_SUPPLY.increment();

        // Mint the token with the token ID and new hash
        _mint(tokenId,hash,uint256(hash),(startNow ? tokenId : 0),itemId,classId,genderId);

        // Let the world know
        emit Mined(tokenId,msg.sender,hash,(startNow ? tokenId : 0),DIFFICULTY_TARGET,DIFFICULTY_RADIUS,itemId,classId,genderId);

        if(startNow){
            emit AttemptStarted(tokenId,tokenId);   
        }
    }

    /**
    * @notice overload mine function to default the startNow bool to TRUE if it is not set
    * @param nonce the nonce solving the difficulty target problem for the message sender
    * @param itemId the item id of the miner's starting item
    * @param classId the class id of the miner
    * @param genderId the gender id of the miner
    */
    function mine(uint256 nonce, uint256 itemId, uint256 classId, uint256 genderId)
        payable
        public
    {
        mine(nonce,itemId,classId,genderId,true);
    }

    /**
    * @notice mint a new token and set new difficulty target values
    * @param tokenId the token id of the miner to be minted
    * @param tokenHash the hash of the token
    * @param hashVal the hash of the token cast to an unsigned integer
    * @param startTokenId the tokenId at which the miner entered the dungeon
    * @param itemId the item id of the miner's starting item
    * @param classId the class id of the miner
    * @param genderId the gender id of the miner
    */
    function _mint(uint256 tokenId, bytes32 tokenHash, uint256 hashVal, uint256 startTokenId, uint256 itemId, uint256 classId, uint256 genderId)
        private
    {
        // Define the escape attempt stats based on provided data
        Attempt memory attempt = Attempt({
            hash: tokenHash,
            startTokenId: startTokenId,
            genderId: uint8(genderId),
            classId: uint8(classId),
            itemId: uint8(itemId)
        });

        // Set the owner of the token to the sender
        OWNERS[tokenId] = msg.sender;

        // Increment the balance of the sender
        BALANCES[msg.sender]++;

        // Set new difficulty target
        DIFFICULTY_TARGET = (hashVal % DIFFICULTY_LIMIT) + DIFFICULTY_RADIUS;

        // Push the attempt to the tokens array
        TOKENS[tokenId] = attempt;

        // Let the world know that a token has been minted
        emit Transfer(address(0),msg.sender,tokenId);
    }

    /**
    * @notice get the hash of a token
    * @param tokenId the token id of the miner
    * @return bytes32 value of the hash of the provided token
    */
    function hashOf(uint256 tokenId)
        external 
        view
        returns(bytes32)
    {
        require(_isValidToken(tokenId),"Invalid token.");
        return TOKENS[tokenId].hash;
    }

    /**
    * @notice check if a token is valid (has been minted and is owned by an address)
    * @param tokenId the token id of the miner
    * @return boolean representing whether or not the token is valid
    */
    function _isValidToken(uint256 tokenId)
        internal
        view
        returns(bool)
    {
        return OWNERS[tokenId] != address(0);
    }

    /**
    *
    *   ERC-721
    *
    */

    /**
    * @notice get the balance of an address
    * @param owner the address to be checked
    * @return uint256 value of the number of miners the address owns
    */
    function balanceOf(address owner)
        external
        view
        returns(uint256)
    {
        return BALANCES[owner];
    }

    /**
    * @notice get the owner of a miner
    * @param tokenId the token id of the miner
    * @return address of the owner
    */
    function ownerOf(uint256 tokenId)
        public
        view
        returns(address)
    {
        require(_isValidToken(tokenId),"invalid");
        return OWNERS[tokenId];
    }

    /**
    * @notice transfer ownership of a miner from one address to another
    * @param from the address to transfer the miner from
    * @param to the address to transfer the miner to
    * @param tokenId the token id of the miner to transfer
    * @param data additional data to send in call to "to"
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
    {
        // Call the transferFrom() function to transfer ownership of a token from one address to another
        transferFrom(from, to, tokenId);

        // Get size of "to" address, if 0 it's a wallet
        uint32 size;

        assembly {
            size := extcodesize(to)
        }

        // Check if the "to" address is not a wallet
        if(size > 0){
            // Not a wallet!

            // Set up ERC-721 interface for accepting safe transfers
            ERC721TokenReceiver receiver = ERC721TokenReceiver(to);

            // Successful transfers will return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` - otherwise the transaction will be reversed
            require(receiver.onERC721Received(msg.sender,from,tokenId,data) == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),"receiver");
        }

    }

    /**
    * @notice overload safeTransferFrom to transfer ownership of a miner from one address to another with blank data
    * @param from the address to transfer the miner from
    * @param to the address to transfer the miner to
    * @param tokenId the token id of the miner to transfer
    */
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external
    {
        safeTransferFrom(from,to,tokenId,"");
    }

    /**
    * @notice transfer ownership of a miner from one address to another
    * @notice make sure "to" is an actual address or this miner could be lost forever
    * @param from the address to transfer the miner from
    * @param to the address to transfer the miner to
    * @param tokenId the token id of the miner to transfer
    */
    function transferFrom(address from, address to, uint256 tokenId)
        public
    {
        // Get the owner of the token
        address owner = ownerOf(tokenId);

        // Ensure that the message sender owns the token or the sender has been authorized for actions on this token or for all actions on behalf of the owner
        require (owner == msg.sender || ALLOWANCE[tokenId] == msg.sender || AUTHORIZED[owner][msg.sender],"permission");

        // Ensure that the owner address specified matches the calculated owner address of the token
        require(owner == from,"owner");

        // Ensure that the recipient address is a valid address
        require(to != address(0),"zero");

        // let the world know
        emit Transfer(from, to, tokenId);

        // Set the owner of the token to the recipient address
        OWNERS[tokenId] = to;

        // Remove one token from the original owner's token ownership counter in the balances array
        BALANCES[from]--;

        // Add one token to the new owner's token ownership counter in the balances array
        BALANCES[to]++;

        // Check if there's been an access allowance made in the past for this token
        if(ALLOWANCE[tokenId] != address(0)){
            // Allowance exists!

            // Delete the existing allowance to revoke token operation access from previously-allowed addresses
            delete ALLOWANCE[tokenId];
        }
    }

    /**
    * @notice approve an address to take action on a specific miner
    * @param approved the address to approve
    * @param tokenId the token id of the miner
    */
    function approve(address approved, uint256 tokenId)
        external
    {
        // Get the owner of the token
        address owner = ownerOf(tokenId);

        // Ensure that the message sender owns the token or the sender is authorized for this token
        require(owner == msg.sender || AUTHORIZED[owner][msg.sender],"permission");

        // Let the world know
        emit Approval(owner, approved, tokenId);

        // Add the approved address to the allowance array
        ALLOWANCE[tokenId] = approved;
    }

    /**
    * @notice approve an address to take action on all miners owned by the sender
    * @param operator the address to approve
    * @param approved whether or not the operator address provided is approved
    */
    function setApprovalForAll(address operator, bool approved)
        external
    {
        // Let the world know
        emit ApprovalForAll(msg.sender,operator, approved);

        // Set authorized boolean for an operator address on behalf of the message sender
        AUTHORIZED[msg.sender][operator] = approved;
    }

    /**
    * @notice return the approved an address for a specific miner
    * @param tokenId the token id of the miner
    * @return address of the approved wallet for a token
    */
    function getApproved(uint256 tokenId)
        external
        view
        returns(address)
    {
        // Check that the token is valid
        require(_isValidToken(tokenId),"invalid");

        // Return the address from the allowance array
        return ALLOWANCE[tokenId];
    }

    /**
    * @notice check if an operator address has been approved to manage all tokens for another address
    * @param owner the address of the miner(s) owner
    * @param operator the address of the approved operator
    * @return boolean representing whether or not the operator is approved for all of owner's tokens
    */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns(bool)
    {
        // Return a boolean if the operator address is found at the owner key in the authorized array
        return AUTHORIZED[owner][operator];
    }

    /**
    *
    *   ERC-721 METADATA
    *
    */

    /**
    * @notice return the Dungeon Miners name
    * @return string representing the token name
    */
    function name()
        external
        pure
        returns(string memory)
    {
        return "Dungeon Miners";
    }

    /**
    * @notice return the abbreviated Dungeon Miners name
    * @return string representing the token abbreviation
    */
    function symbol()
        external
        pure
        returns(string memory)
    {
        return "DM";
    }

    /**
    * @notice return the data URI for a given token
    * @param tokenId the token id of the miner
    * @return string representing a data uri
    */
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        // Ensure the token id is valid
        require(_isValidToken(tokenId),"Invalid token");

        // Return generated data from _tokenURI function
        return _tokenURI(tokenId);
    }

    /**
    *
    *   CONTRACT-LEVEL METADATA
    *
    */

    /**
    * @notice return the data URI for contract-level data
    * @return string representing a data uri
    */
    function contractURI()
        external
        pure
        returns (string memory)
    {
        return 'data:text/plain,{"name":"Dungeon Miners","description":"Dungeon Miners is a fully on-chain, procedurally-generated dungeon crawler where players can mine for and mint NFTs that evolve as more and more NFTs are minted in an attempt to escape a 48-chamber dungeon and win ETH prizes.","image":"data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMDAlIiBoZWlnaHQ9IjEwMCUiIHZpZXdCb3g9IjAgMCA2NCA2NCIgcHJlc2VydmVBc3BlY3RSYXRpbz0ieE1pZFlNaWQgbWVldCI+PGRlZnM+PG1hc2sgaWQ9Im9tIiBtYXNrVW5pdHM9InVzZXJTcGFjZU9uVXNlIj48cmVjdCB3aWR0aD0iNiIgaGVpZ2h0PSI3IiBmaWxsPSIjZmZmIi8+PHJlY3QgeD0iMiIgeT0iMSIgd2lkdGg9IjIiIGhlaWdodD0iNSIgZmlsbD0iIzAwMCIvPjwvbWFzaz48bWFzayBpZD0icm0iIG1hc2tVbml0cz0idXNlclNwYWNlT25Vc2UiPjxyZWN0IHdpZHRoPSI2IiBoZWlnaHQ9IjciIGZpbGw9IiNmZmYiLz48cmVjdCB4PSIyIiB5PSIxIiB3aWR0aD0iMiIgaGVpZ2h0PSIzIiBmaWxsPSIjMDAwIi8+PC9tYXNrPjxwYXRoIGlkPSJkIiBkPSJNMCwwaDV2MWgxdjVoLTF2MWgtNXoiIHN0eWxlPSJtYXNrOnVybCgjb20pIi8+PHBhdGggaWQ9InUiIGQ9Ik0wLDBoMnY2aDJ2LTZoMnY3aC02eiIvPjxwYXRoIGlkPSJuIiBkPSJNMCwwaDF2MWgxdjFoMXYxaDF2LTNoMnY3aC0xdi0xaC0xdi0xaC0xdi0xaC0xdjNoLTJ6Ii8+PHBhdGggaWQ9ImciIGQ9Ik0wLDBoNnYyaC0ydi0xaC0ydjVoMnYtMmgtMXYtMWgzdjRoLTZ6Ii8+PHBhdGggaWQ9ImUiIGQ9Ik0wLDBoNnYxaC00djJoM3YxaC0zdjJoNHYxaC02eiIvPjxwYXRoIGlkPSJvIiBkPSJNMCwwaDZ2N2gtNnoiIHN0eWxlPSJtYXNrOnVybCgjb20pIi8+PHBhdGggaWQ9Im0iIGQ9Ik0wLDBoMXYxaDF2MWgxdjFoMXYtMWgxdi0xaDF2LTFoMXY3aC0ydi0zaC0xdjJoLTF2LTJoLTF2M2gtMnoiLz48cGF0aCBpZD0iaSIgZD0iTTAsMGg2djFoLTJ2NWgydjFoLTZ2LTFoMnYtNWgtMnoiLz48cGF0aCBpZD0iciIgZD0iTTAsMGg2djRoLTF2MWgxdjJoLTJ2LTJoLTJ2MmgtMnoiIHN0eWxlPSJtYXNrOnVybCgjcm0pIi8+PHBhdGggaWQ9InMiIGQ9Ik0wLDBoNnYyaC0ydi0xaC0ydjJoNHY0aC02di0yaDJ2MWgydi0yaC00eiIvPjxnIGlkPSJkdW5nZW9uIj48dXNlIGhyZWY9IiNkIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwLDQpIi8+PHVzZSBocmVmPSIjdSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNywyKSIvPjx1c2UgaHJlZj0iI24iIHRyYW5zZm9ybT0idHJhbnNsYXRlKDE0LDEpIi8+PHVzZSBocmVmPSIjZyIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMjEsMCkiLz48dXNlIGhyZWY9IiNlIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgyOCwxKSIvPjx1c2UgaHJlZj0iI28iIHRyYW5zZm9ybT0idHJhbnNsYXRlKDM1LDIpIi8+PHVzZSBocmVmPSIjbiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoNDIsNCkiLz48L2c+PGcgaWQ9Im1pbmVycyI+PHVzZSBocmVmPSIjbSIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMywyKSIvPjx1c2UgaHJlZj0iI2kiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDExLDEpIi8+PHVzZSBocmVmPSIjbiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMTgsMCkiLz48dXNlIGhyZWY9IiNlIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgyNSwwKSIvPjx1c2UgaHJlZj0iI3IiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDMyLDEpIi8+PHVzZSBocmVmPSIjcyIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMzksMikiLz48L2c+PC9kZWZzPjxyZWN0IGhlaWdodD0iNjQiIHdpZHRoPSI2NCIgZmlsbD0iIzA5MDgwYiIvPjxnIHRyYW5zZm9ybT0idHJhbnNsYXRlKDgsMTgpIj48Zz48cmVjdCB4PSIyMyIgd2lkdGg9IjIiIGhlaWdodD0iMjgiIGZpbGw9IiM3NTRjMjQiLz48cmVjdCB4PSIyMyIgd2lkdGg9IjEiIGhlaWdodD0iMjgiIGZpbGw9IiM4YzYyMzkiLz48cmVjdCB4PSIyMyIgeT0iNSIgd2lkdGg9IjIiIGhlaWdodD0iMSIgZmlsbD0icmdiYSgwLDAsMCwwLjIpIi8+PHBhdGggZD0iTTIsOGgxdi0yaDJ2LTFoM3YtMWg0di0xaDV2LTFoNXYtMWg0djFoNXYxaDV2MWg0djFoM3YxaDJ2MmgxdjFoLTF2LTFoLTJ2LTFoLTN2LTFoLTR2LTFoLTV2LTFoLTV2MWgtNHYtMWgtNXYxaC01djFoLTR2MWgtM3YxaC0ydjFoLTF6IiBmaWxsPSIjOTU5NTk1Ii8+PHBhdGggZD0iTTIsOGgxdi0yaDJ2LTFoM3YtMWg0di0xaDV2LTFoNXYtMWg0djFoLTR2MWgtNXYxaC01djFoLTR2MWgtM3YxaC0ydjJoLTF6IiBmaWxsPSJyZ2JhKDI1NSwyNTUsMjU1LDAuMikiLz48cGF0aCBkPSJNMjIsNGg0di0xaDV2MWg1djFoNHYxaDN2MWgydjFoMXYxaC0xdi0xaC0ydi0xaC0zdi0xaC00di0xaC01di0xaC01djFoLTR6IiBmaWxsPSJyZ2JhKDAsMCwwLDAuMikiLz48L2c+PHVzZSBocmVmPSIjZHVuZ2VvbiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMCw4KSIgZmlsbD0iIzUyM2YyYyIvPjx1c2UgaHJlZj0iI21pbmVycyIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMCwxOCkiIGZpbGw9IiM1MjNmMmMiLz48dXNlIGhyZWY9IiNkdW5nZW9uIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwLDcpIiBmaWxsPSIjZmZmIi8+PHVzZSBocmVmPSIjbWluZXJzIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwLDE3KSIgZmlsbD0iI2ZmZiIvPjwvZz48L3N2Zz4=","external_link":"https://dungeonminers.com","seller_fee_basis_points":250,"fee_recipient":"0x79ac53F63728684F5B21B6302FC5Cef5A8E8b7e9"}';
    }

    /**
    *
    *   ERC-165
    *
    */

    /**
    * @notice check if this contract implements an interface
    * @param interfaceID the interface identifier, as specified in ERC-165
    * @return boolean representing whether or not the interface is supported
    */
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns(bool)
    {
        return supportedInterfaces[interfaceID];
    }
}

// Define the ERC721TokenReceiver interface

interface ERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}