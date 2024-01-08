//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./console.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./ITraits.sol";

contract DogewoodV2 is ERC721 {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/
    // max number of tokens that can be minted - 5000 in production
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant GENESIS_SUPPLY = 2500;
    uint256 public constant mintCooldown = 12 hours;

    // Helpers to get Percentages
    uint256 constant tenPct = (type(uint16).max / 100) * 10;
    uint256 constant fifteenPct = (type(uint16).max / 100) * 15;
    uint256 constant fiftyPct = (type(uint16).max / 100) * 50;

    bool public presaleActive;
    bool public saleActive;
    mapping (address => uint8) public whitelist;
    mapping (address => uint8) public ogWhitelist;

    uint256 public mintPriceEth;
    uint256 public mintPriceZug;
    uint16 public constant MAX_ZUG_MINT = 200;
    uint16 public zugMintCount;

    // list of probabilities for each trait type
    // 0 - 6 are associated with head, breed, color, class, armor, offhand, mainhand
    uint8[][7] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 6 are associated with head, breed, color, class, armor, offhand, mainhand
    uint8[][7] public aliases;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) public existingCombinations;

    bool public rerollTreatOnly;
    uint256 public rerollPriceEth;
    uint256 public rerollPriceZug;
    uint256[] public rerollPrice;

    // level 1-20
    uint256[] public upgradeLevelPrice;

    bytes32 internal entropySauce;

    ERC20 public treat;
    ERC20 public zug;

    mapping(address => bool) public auth;
    mapping(uint256 => Doge) internal doges;
    mapping(uint256 => Action) public activities;
    mapping(uint256 => Log) public mintLogs;
    mapping(RerollTypes => mapping(uint256 => uint256)) public rerollCountHistory; // rerollType => tokenId => rerollCount

    // reference to Traits
    ITraits public traits;

    mapping(uint256 => uint256) public rerollBlocks;

    function setAddresses(
        address _traits,
        address _treat,
        address _zug
    ) external onlyOwner {
        traits = ITraits(_traits);
        treat = ERC20(_treat);
        zug = ERC20(_zug);
    }

    function setAuth(address add, bool isAuth) external onlyOwner {
        auth[add] = isAuth;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        admin = newOwner;
    }

    function setPresaleStatus(bool _status) external onlyOwner {
        presaleActive = _status;
    }

    function setSaleStatus(bool _status) external onlyOwner {
        saleActive = _status;
    }

    function setMintPrice(uint256 _mintPriceEth, uint256 _mintPriceZug)
        external
        onlyOwner
    {
        mintPriceEth = _mintPriceEth;
        mintPriceZug = _mintPriceZug;
    }

    function setRerollTreatOnly(bool _rerollTreatOnly) external onlyOwner {
        rerollTreatOnly = _rerollTreatOnly;
    }

    function setRerollPrice(
        uint256 _rerollPriceEth,
        uint256 _rerollPriceZug,
        uint256[] calldata _rerollPriceTreat
    ) external onlyOwner {
        rerollPriceEth = _rerollPriceEth;
        rerollPriceZug = _rerollPriceZug;
        rerollPrice = _rerollPriceTreat;
    }

    function setUpgradeLevelPrice(uint256[] calldata _upgradeLevelPrice) external onlyOwner {
        upgradeLevelPrice = _upgradeLevelPrice;
    }

    function editWhitelist(address[] calldata wlAddresses) external onlyOwner {
        for(uint256 i; i < wlAddresses.length; i++){
            whitelist[wlAddresses[i]] = 2;
        }
    }

    function editOGWhitelist(address[] calldata wlAddresses) external onlyOwner {
        for(uint256 i; i < wlAddresses.length; i++){
            ogWhitelist[wlAddresses[i]] = 1;
        }
    }

    /** RENDER */

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        // doges[tokenId] empty check
        // require(tokenId > 0 && tokenId < totalSupply, "ERC721Metadata: URI query for nonexistent token");
        return traits.tokenURI(tokenId);
    }

    event ActionMade(
        address owner,
        uint256 id,
        uint256 timestamp,
        uint8 activity
    );

    /*///////////////////////////////////////////////////////////////
                DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    struct Doge {
        uint8 head;
        uint8 breed;
        uint8 color;
        uint8 class;
        uint8 armor;
        uint8 offhand;
        uint8 mainhand;
        uint16 level;
    }

    enum Actions {
        UNSTAKED,
        FARMING
    }
    struct Action {
        address owner;
        uint88 timestamp;
        Actions action;
    }
    struct Log {
        address owner;
        uint88 timestamp;
    }
    enum RerollTypes {
        BREED,
        CLASS
    }

    /*///////////////////////////////////////////////////////////////
                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    function initialize() public onlyOwner {
        admin = msg.sender;
        auth[msg.sender] = true;

        // initialize state
        presaleActive = false;
        saleActive = false;
        mintPriceEth = 0.065 ether;
        mintPriceZug = 300 ether;

        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // head
        rarities[0] = [173, 155, 255, 206, 206, 206, 114, 114, 114];
        aliases[0] = [2, 2, 8, 0, 0, 0, 0, 1, 1];
        // breed
        rarities[1] = [255, 255, 255, 255, 255, 255, 255, 255];
        aliases[1] = [7, 7, 7, 7, 7, 7, 7, 7];
        // color
        rarities[2] = [255, 188, 255, 229, 153, 76];
        aliases[2] = [2, 2, 5, 0, 0, 1];
        // class
        rarities[3] = [229, 127, 178, 255, 204, 204, 204, 102];
        aliases[3] = [2, 2, 3, 7, 0, 0, 1, 1];
        // armor
        rarities[4] = [255];
        aliases[4] = [0];
        // offhand
        rarities[5] = [255];
        aliases[5] = [0];
        // mainhand
        rarities[6] = [255];
        aliases[6] = [0];

        rerollTreatOnly = false;
        // set reroll price
        rerollPriceEth = 0.01 ether;
        rerollPriceZug = 50 ether;
        rerollPrice = [
            6 ether,
            12 ether,
            24 ether,
            48 ether,
            96 ether
        ];

        // set upgrade level price
        // level 1-20
        upgradeLevelPrice = [
            0 ether,
            12 ether,
            16 ether,
            20 ether,
            24 ether,
            30 ether,
            36 ether,
            42 ether,
            48 ether,
            54 ether,
            62 ether,
            70 ether,
            78 ether,
            86 ether,
            96 ether,
            106 ether,
            116 ether,
            126 ether,
            138 ether,
            150 ether
        ];
    }

    /*///////////////////////////////////////////////////////////////
                    MODIFIERS 
    //////////////////////////////////////////////////////////////*/

    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly {
            size := extcodesize(acc)
        }

        require(
            auth[msg.sender] || (msg.sender == tx.origin && size == 0),
            "you're trying to cheat!"
        );
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase, entropySauce));
    }

    modifier mintCoolDownPassed(uint256 id) {
        Log memory log_ = mintLogs[id];
        require(
            block.timestamp >= log_.timestamp + mintCooldown,
            "still in cool down"
        );
        _;
    }

    modifier ownerOfDoge(uint256 id) {
        require(
            ownerOf[id] == msg.sender || activities[id].owner == msg.sender,
            "not your doge"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == admin);
        _;
    }

    modifier genesisMinting(uint8 amount) {
        require(minted + amount <= GENESIS_SUPPLY, "genesis all minted");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function mintReserved(address to, uint8 amount) public genesisMinting(amount) onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(to);
        }
    }

    function mintOG(address to, uint8 amount) public genesisMinting(amount) noCheaters {
        require(amount <= ogWhitelist[msg.sender], "Exceeds amount");

        ogWhitelist[msg.sender] = ogWhitelist[msg.sender] - amount;

        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(to);
        }
    }

    function presaleMintWithEth(uint8 amount) public payable genesisMinting(amount) noCheaters {
        require(presaleActive, "Presale must be active to mint");
        require(amount <= whitelist[msg.sender], "Exceeds max amount");
        require(msg.value >= mintPriceEth * amount, "Value below price");

        whitelist[msg.sender] = whitelist[msg.sender] - amount;

        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(msg.sender);
        }
    }

    function presaleMintWithZug(uint8 amount) public genesisMinting(amount) noCheaters {
        require(presaleActive, "Presale must be active to mint");
        require(whitelist[msg.sender] > 0, "No tokens reserved for this address");
        require(amount <= whitelist[msg.sender], "Exceeds max amount");
        require(zugMintCount+amount <= MAX_ZUG_MINT, "Exceeds max zug mint");

        whitelist[msg.sender] = whitelist[msg.sender] - amount;

        zug.transferFrom(msg.sender, address(this), mintPriceZug * amount);
        zugMintCount = zugMintCount + amount;
        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(msg.sender);
        }
    }

    function mintWithEth(uint8 amount) public payable genesisMinting(amount) noCheaters {
        require(saleActive, "Sale must be active to mint");
        require(amount <= 2, "Exceeds max amount");
        require(msg.value >= mintPriceEth * amount, "Value below price");

        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(msg.sender);
        }
    }

    function mintWithZug(uint8 amount) public genesisMinting(amount) noCheaters {
        require(saleActive, "Sale must be active to mint");
        require(amount <= 2, "Exceeds max amount");
        require(zugMintCount+amount <= MAX_ZUG_MINT, "Exceeds max zug mint");
        zug.transferFrom(msg.sender, address(this), mintPriceZug * amount);
        zugMintCount = zugMintCount + amount;
        for (uint256 i = 0; i < amount; i++) {
            _mintDoge(msg.sender);
        }
    }

    function recruit(uint256 id) public ownerOfDoge(id) mintCoolDownPassed(id) noCheaters {
        require(minted <= MAX_SUPPLY, "all supply minted");
        uint256 cost = _getMintingPrice();
        if (cost > 0) treat.burn(msg.sender, cost);
        _mintDoge(msg.sender);
    }

    function upgradeLevelWithTreat(uint256 id)
        public
        ownerOfDoge(id)
        mintCoolDownPassed(id)
        noCheaters
    {
        _claim(id); // Need to claim to not have equipment reatroactively multiplying

        uint16 curVal = doges[id].level;
        require(curVal < 20, "already max level");
        treat.burn(msg.sender, upgradeLevelPrice[curVal]);
        doges[id].level = curVal + 1;
    }

        // mintCoolDownPassed(id)
    function rerollWithEth(uint256 id, RerollTypes rerollType)
        public
        payable
        ownerOfDoge(id)
        mintCoolDownPassed(id)
        noCheaters
    {
        require(!rerollTreatOnly, "Only TREAT for reroll");
        require(msg.value >= rerollPriceEth, "Value below price");

        _reroll(id, rerollType);
    }

    function rerollWithZug(uint256 id, RerollTypes rerollType)
        public
        ownerOfDoge(id)
        mintCoolDownPassed(id)
        noCheaters
    {
        require(!rerollTreatOnly, "Only TREAT for reroll");
        zug.transferFrom(msg.sender, address(this), rerollPriceZug);
        _reroll(id, rerollType);
    }

    function rerollWithTreat(uint256 id, RerollTypes rerollType)
        public
        ownerOfDoge(id)
        mintCoolDownPassed(id)
        noCheaters
    {
        uint256 price_ = rerollPrice[
            rerollCountHistory[rerollType][id] < 5
                ? rerollCountHistory[rerollType][id]
                : 5
        ];
        treat.burn(msg.sender, price_);
        _reroll(id, rerollType);
    }

    function _reroll(
        uint256 id,
        RerollTypes rerollType
    ) internal {
        rerollBlocks[id] = block.number;
        uint256 rand_ = _rand();

        if (rerollType == RerollTypes.BREED) {
            doges[id].breed = uint8(_randomize(rand_, "BREED", id)) % uint8(rarities[1].length);
        } else if (rerollType == RerollTypes.CLASS) {
            uint16 randClass = uint16(_randomize(rand_, "CLASS", id));
            doges[id].class = selectTrait(randClass, 3);
        }
        rerollCountHistory[rerollType][id]++;
    }

    /**
    * allows owner to withdraw funds from minting
    */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        zug.transfer(msg.sender, zug.balanceOf(address(this)));
    }

    function doAction(uint256 id, Actions action_)
        public
        ownerOfDoge(id)
        noCheaters
    {
        _doAction(id, msg.sender, action_);
    }

    function _doAction(
        uint256 id,
        address dogeOwner,
        Actions action_
    ) internal {
        Action memory action = activities[id];
        require(action.action != action_, "already doing that");

        // Picking the largest value between block.timestamp, action.timestamp and startingTime
        uint88 timestamp = uint88(
            block.timestamp > action.timestamp
                ? block.timestamp
                : action.timestamp
        );

        if (action.action == Actions.UNSTAKED) _transfer(dogeOwner, address(this), id);
        else {
            if (block.timestamp > action.timestamp) _claim(id);
            timestamp = timestamp > action.timestamp ? timestamp : action.timestamp;
        }

        address owner_ = action_ == Actions.UNSTAKED ? address(0) : dogeOwner;
        if (action_ == Actions.UNSTAKED) _transfer(address(this), dogeOwner, id);

        activities[id] = Action({
            owner: owner_,
            timestamp: timestamp,
            action: action_
        });
        emit ActionMade(dogeOwner, id, block.timestamp, uint8(action_));
    }

    function doActionWithManyDoges(uint256[] calldata ids, Actions action_)
        external
    {
        for (uint256 index = 0; index < ids.length; index++) {
            _doAction(ids[index], msg.sender, action_);
        }
    }

    function claim(uint256[] calldata ids) external {
        for (uint256 index = 0; index < ids.length; index++) {
            _claim(ids[index]);
        }
    }

    function _claim(uint256 id) internal noCheaters {
        Action memory action = activities[id];

        if (block.timestamp <= action.timestamp) return;

        uint256 timeDiff = uint256(block.timestamp - action.timestamp);

        if (action.action == Actions.FARMING)
            treat.mint(
                action.owner,
                claimableTreat(timeDiff, id, action.owner)
            );

        activities[id].timestamp = uint88(block.timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                    VIEWERS
    //////////////////////////////////////////////////////////////*/

    function getTokenTraits(uint256 tokenId) external view returns (Doge memory) {
        if (rerollBlocks[tokenId] == block.number) return doges[0];
        return doges[tokenId];
    }

    function claimable(uint256 id) external view returns (uint256) {
        if (activities[id].action == Actions.FARMING) {
            uint256 timeDiff = block.timestamp > activities[id].timestamp
                ? uint256(block.timestamp - activities[id].timestamp)
                : 0;
            return claimableTreat(timeDiff, id, activities[id].owner);
        }
        return 0;
    }

    function getGenesisSupply() external pure returns (uint256) {
        return GENESIS_SUPPLY;
    }

    function name() external pure returns (string memory) {
        return "Doges";
    }

    function symbol() external pure returns (string memory) {
        return "Doges";
    }

    /*///////////////////////////////////////////////////////////////
                    MINT FUNCTION
    //////////////////////////////////////////////////////////////*/

    function _mintDoge(address to) internal {
        uint16 id = uint16(totalSupply + 1);
        rerollBlocks[id] = block.number;
        uint256 seed = random(id);
        generate(id, seed);
        _mint(to, id);
        mintLogs[id] = Log({
            owner: to,
            timestamp: uint88(block.timestamp)
        });
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL  HELPERS
    //////////////////////////////////////////////////////////////*/

    function claimableTreat(uint256 timeDiff, uint256 id, address owner_)
        internal
        view
        returns (uint256)
    {
        Doge memory doge = doges[id];
        uint256 rand_ = _rand();

        uint256 treatAmount = (timeDiff * 1 ether) / 1 days;
        if (doge.class == 0) { // Warrior
            uint16 randPlus = uint16(_randomize(rand_, "Warrior1", id));
            if (randPlus < fifteenPct) return treatAmount * 115 / 100;

            randPlus = uint16(_randomize(rand_, "Warrior2", id));
            if (randPlus < fifteenPct) return treatAmount * 85 / 100;
            return treatAmount;
        } else if(doge.class == 1) { // Rogue
            uint16 randPlus = uint16(_randomize(rand_, "Rogue", id));
            if (randPlus < tenPct) return treatAmount * 3;
            return treatAmount;
        } else if(doge.class == 2) { // Mage
            uint16 randPlus = uint16(_randomize(rand_, "Mage", id));
            if (randPlus < fiftyPct) return treatAmount * 1125 / 1000; // treatAmount * 15 / 10 * 75 / 100
            return treatAmount * 15 / 10;
        } else if(doge.class == 3) { // Hunter
            return treatAmount * 125 / 100;
        } else if(doge.class == 4) { // Cleric
            return treatAmount;
        } else if(doge.class == 5) { // Bard
            uint256 balance = balanceOf[owner_];
            uint256 boost = 10 + (balance > 10 ? 10 : balance);
            return treatAmount * boost / 10;
        } else if(doge.class == 6) { // Forager
            return treatAmount * (1 + ((doge.level - 1) / 3));
        } else if(doge.class == 7) { // Merchant
            return treatAmount * (8 + (rand_ % 6)) / 10;
        }
        
        return treatAmount;
    }

    /**
    * generates traits for a specific token, checking to make sure it's unique
    * @param tokenId the id of the token to generate traits for
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t - a struct of traits for the given token ID
    */
    function generate(uint256 tokenId, uint256 seed) internal returns (Doge memory t) {
        t = selectTraits(seed);
        doges[tokenId] = t;
        return t;

        // keep the following code for future use, current version using different seed, so no need for now
        // if (existingCombinations[structToHash(t)] == 0) {
        //     doges[tokenId] = t;
        //     existingCombinations[structToHash(t)] = tokenId;
        //     return t;
        // }
        // return generate(tokenId, random(seed));
    }

    /**
    * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
    * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
    * probability & alias tables are generated off-chain beforehand
    * @param seed portion of the 256 bit seed to remove trait correlation
    * @param traitType the trait type to select a trait for 
    * @return the ID of the randomly selected trait
    */
    function selectTrait(uint16 seed, uint8 traitType) internal view returns (uint8) {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
    * selects the species and all of its traits based on the seed value
    * @param seed a pseudorandom 256 bit number to derive traits from
    * @return t -  a struct of randomly selected traits
    */
    function selectTraits(uint256 seed) internal view returns (Doge memory t) {    
        t.head = selectTrait(uint16(seed & 0xFFFF), 0);
        seed >>= 16;
        t.breed = selectTrait(uint16(seed & 0xFFFF), 1);
        seed >>= 16;
        t.color = selectTrait(uint16(seed & 0xFFFF), 2);
        seed >>= 16;
        t.class = selectTrait(uint16(seed & 0xFFFF), 3);
        seed >>= 16;
        t.armor = selectTrait(uint16(seed & 0xFFFF), 4);
        seed >>= 16;
        t.offhand = selectTrait(uint16(seed & 0xFFFF), 5);
        seed >>= 16;
        t.mainhand = selectTrait(uint16(seed & 0xFFFF), 6);
        t.level = 1;
    }

    /**
    * converts a struct to a 256 bit hash to check for uniqueness
    * @param s the struct to pack into a hash
    * @return the 256 bit hash of the struct
    */
    function structToHash(Doge memory s) internal pure returns (uint256) {
        return uint256(bytes32(
        abi.encodePacked(
            s.head,
            s.breed,
            s.color,
            s.class,
            s.armor,
            s.offhand,
            s.mainhand,
            s.level
        )
        ));
    }

    /// @dev Create a bit more of randomness
    function _randomize(
        uint256 rand,
        string memory val,
        uint256 spicy
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    function _rand() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        entropySauce
                    )
                )
            );
    }

    /**
    * generates a pseudorandom number
    * @param seed a value ensure different outcomes for different sources in the same block
    * @return a pseudorandom value
    */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }

    function _getMintingPrice() internal view returns (uint256) {
        uint256 supply = minted;
        if (supply < 2500) return 0;
        if (supply < 3000) return 4 ether;
        if (supply < 4600) return 25 ether;
        if (supply < 5000) return 85 ether;
        return 85 ether;
    }
}
