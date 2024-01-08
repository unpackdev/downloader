pragma solidity ^0.8.7;

import "./SafeMath.sol";
import "./Counters.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";

import "./VRFConsumerBase.sol";

import "./ILoot.sol";
import "./ILootComponents.sol";
import "./Base64.sol";

contract Quest is ERC721Enumerable, VRFConsumerBase, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter public currentTurn;

    event GameStarted();
    event RequestedRandomness(uint16 turnNumber, bytes32 requestId);
    event RandomnessReceived(
        bytes32 requestId,
        uint16 turnNumber,
        uint256 randomness
    );
    event Attack(
        uint16 turnNumber,
        uint16 lootId,
        uint8 damageDealt,
        bool attackModifier,
        bool supportModifier,
        bool addedSupportModifier,
        uint32 dragonHP
    );
    event DragonSlain();
    event AGLDDistributed();
    event AGLDClaimed(uint16 turnNumber, uint256 amount);

    struct Turn {
        uint8 damageDealt;
        uint16 turnNumber;
        uint16 lootId;
        uint16 cumulativeTurnsPlayed;
        uint32 cumulativeDamageDealt;
        uint32 dragonHP;
        bool hadAttackModifier;
        bool hadSupportModifier;
        bool addedSupportModifier;
        bool dragonSlayed;
        address attacker;
    }

    struct AttackRecord {
        uint32 cumulativeDamageDealt;
        uint32 cumulativeSupportDamageDealt;
        uint16 turnsPlayedByAttacker;
        uint16 lastTurn;
    }

    uint256 public constant price = 100000000000000000; // 0.1 ETH
    uint256 public constant agldPrice = 100000000000000000000; // 100 AGLD
    uint256 public constant MIN_POT_SIZE = 400000 ether; // 400k AGLD
    uint8 public constant MIN_DAMAGE = 25;
    uint8 public constant MAX_DAMAGE = 200;
    uint8 public constant ATTACK_MODIFIER = 25; // MIN_DAMAGE * 0.25; save some gas
    uint8 public constant SUPPORT_MODIFIER = 50; // MIN_DAMAGE * 0.5
    uint32 public dragonStartingHP;
    uint32 public dragonCurrentHP;
    bool public vrfLock = true;
    bool public distributed = false;
    uint8[4] private numWinners = [100, 40, 7, 1];
    uint256[4] private drops = [
        uint256(1000 ether),
        uint256(2500 ether),
        uint256(10000 ether),
        uint256(100000 ether)
    ];

    address public lootContractAddress;
    address public lootComponentsContractAddress;
    address public agldContractAddress;

    ILoot public lootContract;
    ILootComponents public lootComponentsContract;
    IERC20 public agldContract;

    bytes32 private s_keyHash;
    uint256 private s_fee;

    address public mostDamageAddress;
    address public mostSupportAddress;
    address public dragonSlayerAddress;

    mapping(uint16 => Turn) private _turnsPlayed;
    mapping(address => AttackRecord) private _attackRecords;
    mapping(bytes32 => uint16) public requestIdToTurn;
    mapping(bytes32 => uint256) public requestIdToRandomNumber;
    mapping(uint16 => uint256) public turnToRandomNumber;
    mapping(uint16 => uint256) public turnToAGLDAvailable;
    mapping(uint16 => bool) public turnToAGLDClaimed;

    constructor(
        address vrfCoordinator,
        address link,
        bytes32 keyHash,
        uint256 fee,
        uint32 startHP,
        address _lootContractAddress,
        address _lootComponentsContractAddress,
        address _agldContractAddress
    )
        ERC721("Quest (for Loot)", "QUEST")
        VRFConsumerBase(vrfCoordinator, link)
        Ownable()
    {
        lootContractAddress = _lootContractAddress;
        lootComponentsContractAddress = _lootComponentsContractAddress;
        agldContractAddress = _agldContractAddress;
        lootContract = ILoot(lootContractAddress);
        lootComponentsContract = ILootComponents(lootComponentsContractAddress);
        agldContract = IERC20(agldContractAddress);
        dragonStartingHP = startHP;
        dragonCurrentHP = dragonStartingHP;
        s_keyHash = keyHash;
        s_fee = fee;
    }

    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK");
        uint16 turnNumber = uint16(currentTurn.current());
        vrfLock = true;
        requestId = requestRandomness(s_keyHash, s_fee);
        requestIdToTurn[requestId] = turnNumber;
        emit RequestedRandomness(turnNumber, requestId);
        return requestId;
    }

    function seedFirstRandomNumber() external onlyOwner returns (bytes32) {
        require(vrfLock == true, "Not locked");
        require(currentTurn.current() == 0, "Already started turns");
        emit GameStarted();
        return getRandomNumber();
    }

    function seedFulfillRandomness(bytes32 requestId, uint256 randomness)
        external
        onlyOwner
    {
        fulfillRandomness(requestId, randomness);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint16 turnNumber = requestIdToTurn[requestId];
        requestIdToRandomNumber[requestId] = randomness;
        turnToRandomNumber[turnNumber] = randomness;
        vrfLock = false;
        emit RandomnessReceived(requestId, turnNumber, randomness);
    }

    function supportModifierWasAdded(
        uint16 previousTurn,
        bool addedSupportModifier
    ) internal view returns (bool) {
        bool supportModifier = false;
        if (previousTurn > 0 && addedSupportModifier == false) {
            // Don't let Divines stack attacks
            (, , , , , , , , , supportModifier, , ) = getTurn(previousTurn);
        }
        return supportModifier;
    }

    function associateTurnWithAttacker(
        address attacker,
        uint16 lootId,
        uint16 turnNumber,
        uint8 damageDealt,
        bool attackModifier,
        bool supportModifier,
        bool addedSupportModifier
    ) internal {
        Turn storage t = _turnsPlayed[turnNumber];
        AttackRecord storage a = _attackRecords[attacker];
        if (mostDamageAddress == address(0)) {
            mostDamageAddress = attacker;
        }
        AttackRecord storage mostDamage = _attackRecords[mostDamageAddress];
        a.cumulativeDamageDealt += damageDealt;
        a.lastTurn = turnNumber;
        a.turnsPlayedByAttacker += 1;
        if (a.cumulativeDamageDealt > mostDamage.cumulativeDamageDealt) {
            mostDamageAddress = attacker;
        }

        t.turnNumber = turnNumber;
        t.attacker = attacker;
        t.lootId = lootId;
        t.damageDealt = damageDealt;
        t.cumulativeDamageDealt = a.cumulativeDamageDealt;
        t.cumulativeTurnsPlayed = a.turnsPlayedByAttacker;
        t.dragonHP = dragonCurrentHP;
        t.hadAttackModifier = attackModifier;
        t.hadSupportModifier = supportModifier;
        t.addedSupportModifier = addedSupportModifier;
        t.dragonSlayed = dragonCurrentHP == 0;
        if (t.dragonSlayed == true) {
            dragonSlayerAddress = attacker;
        }
    }

    function associateSupportDamageWithAttacker(
        uint16 turnNumber,
        uint8 damageDealt,
        bool supportModifier
    ) internal {
        Turn storage t = _turnsPlayed[turnNumber];
        AttackRecord storage a = _attackRecords[t.attacker];
        if (mostSupportAddress == address(0)) {
            mostSupportAddress = t.attacker;
        }
        AttackRecord storage mostSupport = _attackRecords[mostSupportAddress];
        if (supportModifier == true && t.addedSupportModifier == true) {
            a.cumulativeSupportDamageDealt += damageDealt;
            if (
                a.cumulativeSupportDamageDealt >
                mostSupport.cumulativeSupportDamageDealt
            ) {
                mostSupportAddress = t.attacker;
            }
        }
    }

    function awardAGLDToTurn(uint16 turnNumber, uint256 agldAmount) internal {
        turnToAGLDAvailable[turnNumber] += agldAmount;
    }

    function attack(uint16 lootId) external payable nonReentrant {
        require(dragonCurrentHP > 0, "Dragon is slain");
        require(vrfLock == false, "Waiting for VRF to return");
        require(lootId > 0 && lootId <= 8000, "Invalid ID");
        require(msg.sender == lootContract.ownerOf(lootId), "Not loot owner");
        require(price <= msg.value, "Insufficient Ether");
        require(
            agldPrice <= agldContract.allowance(msg.sender, address(this)),
            "AGLD spend not approved"
        );

        require(
            agldContract.transferFrom(msg.sender, address(this), agldPrice),
            "AGLD could not be transferred"
        );

        uint16 previousTurn = uint16(currentTurn.current());
        currentTurn.increment();
        uint16 newTurn = uint16(currentTurn.current());

        bool attackModifier = hasAttackModifier(lootId);
        bool addedSupportModifier = hasSupportModifier(lootId);
        bool supportModifier = supportModifierWasAdded(
            previousTurn,
            addedSupportModifier
        );
        uint16 turnModulo = newTurn % 512;
        uint8 damageDealt = getAttackDamage(
            newTurn,
            attackModifier,
            supportModifier,
            turnModulo
        );
        dragonCurrentHP = dragonCurrentHP - damageDealt;

        associateTurnWithAttacker(
            _msgSender(),
            lootId,
            newTurn,
            damageDealt,
            attackModifier,
            supportModifier,
            addedSupportModifier
        );
        associateSupportDamageWithAttacker(
            previousTurn,
            damageDealt,
            supportModifier
        );

        emit Attack(
            newTurn,
            lootId,
            damageDealt,
            attackModifier,
            supportModifier,
            addedSupportModifier,
            dragonCurrentHP
        );

        if (dragonCurrentHP > 0 && turnModulo == 0) {
            getRandomNumber(); // get every 512 turns or on first turn
        }
        if (dragonCurrentHP == 0) {
            emit DragonSlain();
            getRandomNumber(); // trigger the final loot drop
        }

        _safeMint(_msgSender(), newTurn);
    }

    function ownerTriggersDistributeLoot() external onlyOwner {
        // final distribution is expensive
        // failsafe in case dragon slayer doesn't do it
        require(dragonCurrentHP == 0, "Dragon is not slain");
        require(vrfLock == false, "Waiting for VRF to return");
        distributeLoot();
    }

    function dragonSlayerTriggersDistributeLoot() external {
        require(dragonCurrentHP == 0, "Dragon is not slain");
        require(vrfLock == false, "Waiting for VRF to return");
        AttackRecord storage dragonSlayer = _attackRecords[dragonSlayerAddress];
        require(
            _msgSender() == ownerOf(dragonSlayer.lastTurn),
            "Must be dragon slayer"
        );
        distributeLoot();
    }

    function distributeLoot() private {
        require(distributed == false, "Already distributed");
        require(dragonCurrentHP == 0, "Dragon is not slain");
        uint256 agldBalance = agldContract.balanceOf(address(this));
        require(agldBalance >= MIN_POT_SIZE, "Not enough AGLD");
        uint16 j = 0;
        uint16 winner;
        uint16 turnNumber = uint16(currentTurn.current());
        uint256 amountDistributed = 0;
        // 1. Reward the dragon slayer.
        AttackRecord storage dragonSlayer = _attackRecords[dragonSlayerAddress];
        awardAGLDToTurn(dragonSlayer.lastTurn, 10000 ether);
        amountDistributed += 10000 ether;
        // 2. Reward the attacker who dealt the most damage.
        AttackRecord storage mostDamage = _attackRecords[mostDamageAddress];
        awardAGLDToTurn(mostDamage.lastTurn, 10000 ether);
        amountDistributed += 10000 ether;
        // 3. Reward the attacker who provided the most support.
        if (mostSupportAddress != address(0)) {
          AttackRecord storage mostSupport = _attackRecords[mostSupportAddress];
          awardAGLDToTurn(mostSupport.lastTurn, 10000 ether);
          amountDistributed += 10000 ether;
        }

        // 4. Get the latest random seed number
        uint256 randomResult = turnToRandomNumber[turnNumber];

        // 5. Award 1,000 AGLD to 100 turns

        uint8 upperLimit = 0;
        for (uint8 i = 0; i < numWinners.length; i++) {
            upperLimit += numWinners[i];
            for (j; j < upperLimit; j++) {
                winner = uint16((random(j, randomResult) % turnNumber) + 1);
                awardAGLDToTurn(winner, drops[i]);
                amountDistributed += drops[i];
            }
        }

        // 8. Find the remaining balance
        uint256 remainingBalance = agldBalance - amountDistributed;

        // 9. Award half of the remaining balance to the slayer & grand prize winner
        if (remainingBalance > 0) {
            uint256 dragonSlayerAdditional = remainingBalance / 2;
            uint256 grandPrizeAdditional = remainingBalance -
                dragonSlayerAdditional;
            awardAGLDToTurn(dragonSlayer.lastTurn, dragonSlayerAdditional);
            awardAGLDToTurn(winner, grandPrizeAdditional);
        }

        distributed = true;
        emit AGLDDistributed();
    }

    function pickupReward(uint16 turnNumber) external nonReentrant {
        require(_msgSender() == ownerOf(turnNumber), "Must own turn");
        require(turnToAGLDAvailable[turnNumber] > 0, "No AGLD to claim");
        require(turnToAGLDClaimed[turnNumber] == false, "AGLD already claimed");
        agldContract.transfer(_msgSender(), turnToAGLDAvailable[turnNumber]);
        turnToAGLDClaimed[turnNumber] = true;
        emit AGLDClaimed(turnNumber, turnToAGLDAvailable[turnNumber]);
    }

    function pickupRewards() external nonReentrant {
        uint256 balance = balanceOf(_msgSender());
        require(balance > 0, "Must own at least 1 turn");
        for (uint256 i = 0; i < balance; i++) {
          uint16 turnNumber = uint16(tokenOfOwnerByIndex(_msgSender(), i));
          if (turnToAGLDAvailable[turnNumber] > 0 && turnToAGLDClaimed[turnNumber] == false) {
            agldContract.transfer(_msgSender(), turnToAGLDAvailable[turnNumber]);
            turnToAGLDClaimed[turnNumber] = true;
            emit AGLDClaimed(turnNumber, turnToAGLDAvailable[turnNumber]);
          }
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
        LINK.transfer(payable(owner()), LINK.balanceOf(address(this)));
    }

    /*
     *
     *   Note: damage is capped to the ceiling amount. I realize this isn't
     *   ideal, but given the complexities involved in ensuring we have
     *   sufficient AGLD to distribute, I did this to simplify the function.
     *   Yes, I also realize this means we mint more NFTs. I promise to make it
     *   up to everyone.
     *
     */
    function getAttackDamage(
        uint16 turnNumber,
        bool attackModifier,
        bool supportModifier,
        uint16 turnModulo
    ) private view returns (uint8) {
        uint8 damageModifier = (attackModifier == true ? ATTACK_MODIFIER : 0) +
            (supportModifier == true ? SUPPORT_MODIFIER : 0);
        uint8 floor = damageModifier + MIN_DAMAGE;
        uint8 ceiling = MAX_DAMAGE - floor;
        uint16 randomIndex = turnNumber - turnModulo;
        uint256 randomResult = turnToRandomNumber[randomIndex];
        uint8 damageDealt = uint8(
            (random(turnNumber, randomResult) % ceiling) + floor
        );
        if (damageDealt > dragonCurrentHP) {
            damageDealt = uint8(dragonCurrentHP);
        }
        return damageDealt;
    }

    function random(uint256 number, uint256 randomResult)
        private
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        block.number,
                        randomResult,
                        number
                    )
                )
            );
    }

    function getAttackRecord(address attacker)
        public
        view
        returns (
            uint32 cumulativeDamageDealt,
            uint32 cumulativeSupportDamageDealt,
            uint16 turnsPlayed,
            uint16 lastTurn
        )
    {
        require(attacker != address(0), "Attack record query for zero address");
        AttackRecord storage a = _attackRecords[attacker];
        cumulativeDamageDealt = a.cumulativeDamageDealt;
        cumulativeSupportDamageDealt = a.cumulativeSupportDamageDealt;
        turnsPlayed = a.turnsPlayedByAttacker;
        lastTurn = a.lastTurn;
    }

    function getTurn(uint16 turnNumber)
        public
        view
        returns (
            address attacker,
            uint16 lootId,
            uint8 damageDealt,
            uint32 cumulativeDamageDealtByAttacker,
            uint16 cumulativeTurnsPlayedByAttacker,
            uint32 dragonHP,
            uint256 agldAvailable,
            bool hadAttackModifier,
            bool hadSupportModifier,
            bool addedSupportModifier,
            bool agldClaimed,
            bool dragonSlayed
        )
    {
        require(turnNumber > 0, "Turn number has to be greater than 0");
        Turn storage t = _turnsPlayed[turnNumber];
        attacker = t.attacker;
        lootId = t.lootId;
        damageDealt = t.damageDealt;
        cumulativeDamageDealtByAttacker = t.cumulativeDamageDealt;
        cumulativeTurnsPlayedByAttacker = t.cumulativeTurnsPlayed;
        dragonHP = t.dragonHP;
        agldAvailable = turnToAGLDAvailable[turnNumber];
        hadAttackModifier = t.hadAttackModifier;
        hadSupportModifier = t.hadSupportModifier;
        addedSupportModifier = t.addedSupportModifier;
        agldClaimed = turnToAGLDClaimed[turnNumber];
        dragonSlayed = t.dragonSlayed;
    }

    function hasAttackModifier(uint256 lootId) public view returns (bool) {
        require(lootId > 0 && lootId <= 8000, "Invalid ID");
        return
            lootComponentsContract.chestComponents(lootId)[0] == 6 ||
            lootComponentsContract.headComponents(lootId)[0] == 6 ||
            lootComponentsContract.waistComponents(lootId)[0] == 6 ||
            lootComponentsContract.footComponents(lootId)[0] == 6 ||
            lootComponentsContract.handComponents(lootId)[0] == 6;
    }

    function hasSupportModifier(uint256 lootId) public view returns (bool) {
        require(lootId > 0 && lootId <= 8000, "Invalid ID");
        return lootComponentsContract.chestComponents(lootId)[0] == 0;
    }

    function isDragonSlain() public view returns (bool) {
        return dragonCurrentHP == 0;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function generateCard(uint16 turnNumber)
        internal
        view
        returns (string memory)
    {
        (, , uint256 damageDealt, , , uint256 dragonHP, , , , , , ) = getTurn(
            turnNumber
        );
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #FFFCFC; font-family: monospace; font-size: 14px; } .title { fill: #FFFCFC; font-family: monospace; font-size: 24px; text-anchor: middle; dominant-baseline: middle; }</style><rect width="100%" height="100%" fill="#003F63" /><text x="175" y="35" class="title">QUESTS FOR LOOT</text><text x="30" y="85" class="base">Turn ',
                    toString(turnNumber),
                    '</text><text x="30" y="115" class="base">Damage: ',
                    toString(damageDealt),
                    ' HP</text><text x="30" y="135" class="base">Remaining: ',
                    toString(dragonHP)
                )
            );
    }

    function generateAttackerInfo(uint16 turnNumber)
        internal
        view
        returns (string memory)
    {
        (
            ,
            uint16 lootId,
            ,
            uint32 cumulativeDamageDealt,
            uint32 turnsPlayed,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = getTurn(turnNumber);
        return
            string(
                abi.encodePacked(
                    ' HP</text><text x="30" y="155" class="base">Loot Bag: #',
                    toString(lootId),
                    '</text><text x="30" y="175" class="base">Turns Played: ',
                    toString(turnsPlayed),
                    '</text><text x="30" y="195" class="base">Total Damage: ',
                    toString(cumulativeDamageDealt)
                )
            );
    }

    function generateBoosts(uint16 turnNumber)
        internal
        view
        returns (string memory)
    {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            bool attackModifier,
            bool supportModifier,
            bool addedSupportModifier,
            ,

        ) = getTurn(turnNumber);
        return
            string(
                abi.encodePacked(
                    '</text><text x="30" y="225" class="base">Damage Boost: ',
                    attackModifier ? "Yes" : "No",
                    '</text><text x="30" y="245" class="base">Support Boost: ',
                    supportModifier ? "Yes" : "No",
                    '</text><text x="30" y="265" class="base">Provided Support: ',
                    addedSupportModifier ? "Yes" : "No",
                    '</text><text x="30" y="295" class="base">'
                )
            );
    }

    function generateUniqueTraits(uint16 turnNumber)
        internal
        view
        returns (string memory)
    {
        (
            ,
            ,
            ,
            ,
            ,
            ,
            uint256 agldAvailable,
            ,
            ,
            ,
            bool agldClaimed,
            bool dragonSlayed
        ) = getTurn(turnNumber);
        return
            string(
                abi.encodePacked(
                    turnNumber == 1
                        ? "First strike!"
                        : dragonSlayed
                        ? "You slayed the dragon!"
                        : "The dragon lives...",
                    '</text><text x="30" y="315" class="base">',
                    agldAvailable > 0
                        ? (agldClaimed == true ? "Claimed: " : "Available: ")
                        : "",
                    agldAvailable > 0 ? toString(agldAvailable / 1 ether) : "",
                    agldAvailable > 0 ? " AGLD" : "",
                    '</text><rect x="322.2" y="325.2" transform="matrix(0.7342 -0.6789 0.6789 0.7342 -136.3816 307.9781)" fill="#F2B138" width="5.9" height="5.9"/><rect x="326.6" y="321.2" transform="matrix(0.7342 -0.6789 0.6789 0.7342 -132.5075 309.8563)" fill="#B78330" width="5.9" height="5.9"/><rect x="326.2" y="329.6" transform="matrix(0.7342 -0.6789 0.6789 0.7342 -138.2598 311.8521)" fill="#B78330" width="5.9" height="5.9"/><rect x="330.6" y="325.6" transform="matrix(0.7342 -0.6789 0.6789 0.7342 -134.3857 313.7304)" fill="#F2B138" width="5.9" height="5.9"/></svg>'
                )
            );
    }

    function generateOpenSeaAttributes(uint16 turnNumber)
        internal
        view
        returns (string memory)
    {
        (
            ,
            uint16 lootId,
            uint8 damageDealt,
            uint32 cumulativeDamageDealtByAttacker,
            uint16 cumulativeTurnsPlayedByAttacker,
            uint32 dragonHP,
            uint256 agldAvailable,
            bool hadAttackModifier,
            bool hadSupportModifier,
            bool addedSupportModifier,
            bool agldClaimed,
            bool dragonSlayed
        ) = getTurn(turnNumber);

        string[3] memory parts;
        parts[0] = string(
            abi.encodePacked(
                '{"trait_type": "Loot", "value": "',
                toString(lootId),
                '"},{"trait_type": "Damage Dealt", "value": ',
                toString(damageDealt),
                '},{"trait_type": "Cumulative Damage Dealt", "display_type": "number", "value": ',
                toString(cumulativeDamageDealtByAttacker),
                '},{"trait_type": "Cumulative Turns Played", "display_type": "number", "value": ',
                toString(cumulativeTurnsPlayedByAttacker)
            )
        );
        parts[1] = string(
            abi.encodePacked(
                '},{"trait_type": "Dragon HP", "value": ',
                toString(dragonHP),
                '},{"trait_type": "AGLD Available", "display_type": "number", "value": ',
                toString(agldAvailable / 1 ether),
                '},{"trait_type": "Damage Boost", "display_type": "boost_number", "value": ',
                hadAttackModifier ? toString(ATTACK_MODIFIER) : toString(0),
                '},{"trait_type": "Support Boost", "display_type": "boost_number", "value": ',
                hadSupportModifier ? toString(SUPPORT_MODIFIER) : toString(0)
            )
        );
        parts[2] = string(
            abi.encodePacked(
                '},{"trait_type": "Provided Support", "value": ',
                addedSupportModifier ? '"Yes"' : '"No"',
                '},{"trait_type": "AGLD Claimed", "value": ',
                agldClaimed ? '"Yes"' : '"No"',
                '},{"trait_type": "Dragon Slayer", "value": ',
                dragonSlayed ? '"Yes"' : '"No"',
                "}"
            )
        );

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );

        return output;
    }

    function tokenURI(uint256 tn) public view override returns (string memory) {
        string[4] memory parts;
        uint16 turnNumber = uint16(tn);

        parts[0] = generateCard(turnNumber);
        parts[1] = generateAttackerInfo(turnNumber);
        parts[2] = generateBoosts(turnNumber);
        parts[3] = generateUniqueTraits(turnNumber);

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Turn ',
                        toString(turnNumber),
                        '", "attributes": [',
                        generateOpenSeaAttributes(turnNumber),
                        '], "description": "Quests for Loot are battle records stored on-chain for a MUD to slay a dragon that\'s ravaging a village. Players must work together to defeat it and reap the rewards!", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }
}
