// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./IWomanSeekersNewDawn.sol";
import "./IERC20.sol";

contract LastWarGame is Ownable {
    IWomanSeekersNewDawn Collection;
    IERC20 public LastToken;

    uint256 public defEnergyAccrual = 90;
    uint256 public energyPriceInTokens = 2;
    uint256 public defaultDamage = 100;

    function enterInGame(uint256[] calldata _tokenIds) public {
        Player storage Newplayer = players[msg.sender];

        require(
            checkOwnershipOfTokens(_tokenIds),
            "you're not owner of token Id"
        );

        Newplayer.qtyBossDefeated = 0;
        Newplayer.energyFactor = 10;
        Newplayer.energyBalance = 0;
        Newplayer.lastTimestampClaimedEnergy = 0;
        Newplayer.amountTokensInGame = _tokenIds.length;
        Newplayer.damage = 100;
        Newplayer.isPlaying = true;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            Newplayer.playingTokenIds.push(_tokenIds[i]);
            require(
                !Collection.viewNotTransferable(_tokenIds[i]),
                "This token already in game"
            );
            Collection.setNotTransferable(_tokenIds[i], true);
        }
    }

    event duelFinished(
        address indexed winner,
        uint256 _indexRoom,
        uint256[] damages,
        bool indexed _wasEnergyFactorIncreased
    );

    event duelAttackLogs(
        address indexed player,
        uint256 indexed _indexRoom,
        uint256[] indexed damages
    );

    event DiscountReceived(address indexed _player);
    event LastTokensGiven(address indexed _player, uint256 indexed _amount);

    event BossDefeated(
        address indexed player,
        uint256 indexed bossLevel,
        uint256[] indexed damages
    );
    event BossLost(
        address indexed player,
        uint256 indexed bossLevel,
        uint256[] indexed damages
    );

    mapping(address => Player) public players;
    mapping(uint256 => bossSpecs) public bosses;

    struct Player {
        uint256 qtyBossDefeated;
        uint256 energyFactor;
        uint256 energyBalance;
        uint256 amountTokensInGame;
        uint256 lastTimestampClaimedEnergy;
        uint256[] playingTokenIds;
        uint256 damage;
        bool isPlaying;
    }

    function getInfoPlayer(
        address _player
    ) public view returns (Player memory) {
        return players[_player];
    }

    struct bossSpecs {
        uint256 health;
        uint256 dodgeChance;
        uint256 attackDamage;
    }

    struct duelInfo {
        uint256 playersNow;
        address[2] players;
        uint256 totalDamagePlayer0;
        uint256 totalDamagePlayer1;
    }

    duelInfo[] public duels;

    constructor(address _collection, address _LastToken) {
        Collection = IWomanSeekersNewDawn(_collection);
        LastToken = IERC20(_LastToken);
        createBoss();
        createBoss();
        createBoss();
        createBoss();
        createNewDuelRoom();
        createNewDuelRoom();
        createNewDuelRoom();
    }

    function createNewDuelRoom() public {
        address[2] memory emptyPlayers;

        duels.push(duelInfo(0, emptyPlayers, 0, 0));
    }

    function random(
        uint256 _value,
        uint256 _salt
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        blockhash(block.number - 1),
                        msg.sender,
                        _salt
                    )
                )
            ) % _value;
    }

    function setDefEnergyAccrual(uint256 _value) public onlyOwner {
        defEnergyAccrual = _value;
    }

    function setEnergyPriceInTokens(uint256 _value) public onlyOwner {
        energyPriceInTokens = _value;
    }

    function setDefaultDamage(uint256 _value) public onlyOwner {
        defaultDamage = _value;
    }

    function isPlayerInDuelAtIndexRoom(
        uint256 _indexRoom
    ) public view returns (bool) {
        require(_indexRoom < duels.length, "Invalid duel index");

        duelInfo storage currentDuel = duels[_indexRoom];
        if (currentDuel.playersNow > 0) {
            if (
                currentDuel.players[0] == msg.sender ||
                currentDuel.players[1] == msg.sender
            ) {
                return true;
            }
        }

        return false;
    }

    // function calculateTestDamage() public view returns(uint) {
    //     return  (defaultDamage * players[msg.sender].energyFactor) * ((random(20,1251250) + 100)/100 );

    // }

    function viewDuelInfo(
        uint256 _indexRoom
    ) public view returns (duelInfo memory) {
        return duels[_indexRoom];
    }

    function doAttackInDuel(uint256 _indexRoom) public {
        duelInfo storage currentDuel = duels[_indexRoom];

        require(isPlayerInDuelAtIndexRoom(_indexRoom), "you're not in room");

        uint salt = 132601;
        uint256[] memory damages = new uint256[](3);

        uint totalDamage;

        for (uint i = 0; i <= 2; i++) {
            uint damage = ((random(10, 1251250) + 100) / 100) *
                players[msg.sender].damage *
                players[msg.sender].energyFactor;
            damages[i] = damage;
            salt += 126512;
            totalDamage += damage;
        }

        if (currentDuel.players[0] == msg.sender) {
            require(
                currentDuel.totalDamagePlayer0 == 0,
                "you're already attacked in duel"
            );

            currentDuel.totalDamagePlayer0 += totalDamage;
            emit duelAttackLogs(msg.sender, _indexRoom, damages);
        } else {
            require(
                currentDuel.totalDamagePlayer1 == 0,
                "you're already attacked in duel"
            );

            currentDuel.totalDamagePlayer1 += totalDamage;
            emit duelAttackLogs(msg.sender, _indexRoom, damages);
        }

        if (
            currentDuel.totalDamagePlayer0 != 0 &&
            currentDuel.totalDamagePlayer1 != 0
        ) {
            //
            uint salt1 = 2151256;
            uint chance = random(100, salt1);
            salt += 12723;

            if (chance <= 5) {}
            bool wasEnergyFactorIncreased;

            if (
                currentDuel.totalDamagePlayer0 > currentDuel.totalDamagePlayer1
            ) {
                LastToken.transfer(currentDuel.players[0], duelPrice * 2);

                if (chance <= 5) {
                    players[currentDuel.players[0]].energyFactor += 1;
                    wasEnergyFactorIncreased = true;
                }

                // порождение ивента + включить был ли увеличен мультипликатор игрока

                emit duelFinished(
                    currentDuel.players[0],
                    _indexRoom,
                    damages,
                    wasEnergyFactorIncreased
                );
            } else {
                LastToken.transfer(currentDuel.players[1], duelPrice * 2);

                if (chance <= 5) {
                    players[currentDuel.players[0]].energyFactor += 1;
                    wasEnergyFactorIncreased = true;
                }
                emit duelFinished(
                    currentDuel.players[1],
                    _indexRoom,
                    damages,
                    wasEnergyFactorIncreased
                );
            }

            delete duels[_indexRoom];
        }
    }

    uint256 public duelPrice = 1000;

    function getActiveDuelForPlayer() public view returns (uint256) {
        for (uint i = 0; i < duels.length; i++) {
            if (
                duels[i].players[0] == msg.sender ||
                duels[i].players[1] == msg.sender
            ) {
                return i;
            }
        }

        revert("could not find player in duel rooms");
    }

    function findAvailableDuel() public view returns (uint256) {
        for (uint i = 0; i < duels.length; i++) {
            if (duels[i].playersNow != 2) {
                return i;
            }
        }

        revert("could not find available duel room");
    }

    function enterInDuel() public {
        duelInfo storage currentDuel = duels[findAvailableDuel()];

        require(
            currentDuel.players[0] != msg.sender &&
                currentDuel.players[1] != msg.sender,
            "you're already in this duel"
        );

        // если мы получили currentDuel значит дуэль рум уже точно может принять игрока

        if (currentDuel.players[0] == address(0)) {
            currentDuel.players[0] = msg.sender;
        } else {
            currentDuel.players[1] = msg.sender;
        }

        LastToken.transferFrom(msg.sender, address(this), duelPrice);

        currentDuel.playersNow++;
    }

    uint bosscounter = 1;

    function createBoss() internal {
        bossSpecs storage newBoss = bosses[bosscounter];

        if (bosscounter == 1) {
            newBoss.health = 3000;
            newBoss.dodgeChance = 25;
            newBoss.attackDamage = 300;
        }

        if (bosscounter == 2) {
            newBoss.health = 6000;
            newBoss.dodgeChance = 30;
            newBoss.attackDamage = 300;
        }

        if (bosscounter == 3) {
            newBoss.health = 9000;
            newBoss.dodgeChance = 40;
            newBoss.attackDamage = 300;
        }

        if (bosscounter == 4) {
            newBoss.health = 12000;
            newBoss.dodgeChance = 50;
            newBoss.attackDamage = 300;
        }

        bosscounter++;
    }

    function leaveGame() public {
        require(players[msg.sender].isPlaying == true, "you're out of game");

        for (
            uint256 i = 0;
            i < players[msg.sender].playingTokenIds.length;
            i++
        ) {
            Collection.setNotTransferable(
                players[msg.sender].playingTokenIds[i],
                false
            );
        }

        delete players[msg.sender];
    }

    function claimDailyEnergy() public {
        require(players[msg.sender].energyFactor >= 1, "you're out of game");
        require(
            block.timestamp >=
                players[msg.sender].lastTimestampClaimedEnergy + 1 minutes,
            "try later"
        );

        players[msg.sender].lastTimestampClaimedEnergy = block.timestamp;
        players[msg.sender].energyBalance +=
            100 +
            (defEnergyAccrual * players[msg.sender].energyFactor);
    }

    function getLastTimestampClaimedEnergy(
        address _player
    ) public view returns (uint) {
        return players[_player].lastTimestampClaimedEnergy;
    }

    function buyEnergyForTokens(uint256 _amountEnergy) public {
        uint256 amountToPayTokens = _amountEnergy * energyPriceInTokens;

        LastToken.approve(address(this), amountToPayTokens);

        LastToken.transferFrom(msg.sender, address(this), amountToPayTokens);

        players[msg.sender].energyBalance += _amountEnergy;
    }

    function setLastToken(address _lastToken) public onlyOwner {
        LastToken = IERC20(_lastToken);
    }

    function withdrawGameTokens() public onlyOwner {
        LastToken.transfer(owner(), LastToken.balanceOf(address(this)));
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function fightWithBoss(uint256 _bossLevel) public {
        require(
            _bossLevel - 1 == players[msg.sender].qtyBossDefeated,
            "not corresponding boss for you"
        );

        require(
            players[msg.sender].energyBalance >= bosses[_bossLevel].health,
            "you don't have enough energy for this boss"
        );
        uint totalDamage;
        uint salt = 1255215;
        uint256[] memory damages = new uint256[](3);

        for (uint i = 0; i <= 2; i++) {
            uint damage = (((random(10, salt) *
                players[msg.sender].damage *
                players[msg.sender].energyFactor) *
                bosses[_bossLevel].dodgeChance) / 100);
            damages[i] = damage;
            salt += 12551;

            totalDamage += damage;
        }

        if (totalDamage >= bosses[_bossLevel].health) {
            players[msg.sender].qtyBossDefeated = _bossLevel;
            emit BossDefeated(msg.sender, _bossLevel, damages);
            players[msg.sender].damage += 100;
        } else {
            unchecked {
                players[msg.sender].energyBalance -=
                    bosses[_bossLevel].attackDamage *
                    3;
            }
            emit BossLost(msg.sender, _bossLevel, damages);
        }
    }

    function checkOwnershipOfTokens(
        uint256[] memory _tokenIds
    ) public view returns (bool) {
        for (uint i = 0; i < _tokenIds.length; i++) {
            // tx origin or msg.sender ?
            if (Collection.ownerOf(_tokenIds[i]) != tx.origin) {
                return false;
            }
        }
        return true;
    }

    mapping(uint256 => bool) public isTokenIdClaimed;

    function isTokensClaimedTreasures(
        uint256[] memory _tokenIds
    ) public view returns (bool) {
        for (uint i = 0; i < _tokenIds.length; i++) {
            if (isTokenIdClaimed[_tokenIds[i]]) {
                return true;
            }
        }
        return false;
    }

    function getFinalTreasures(uint256[] memory _tokenIds, uint _salt) public {
        require(
            players[msg.sender].qtyBossDefeated == 4,
            "you have to defeat all bosses"
        );
        require(
            checkOwnershipOfTokens(_tokenIds),
            "you're not owner of these tokenIds"
        );
        require(!isTokensClaimedTreasures(_tokenIds), "tokens were claimed");

        for (uint i = 0; i < _tokenIds.length; i++) {
            isTokenIdClaimed[_tokenIds[i]] = true;
            uint chance = random(10, _salt);
            _salt += 16236;

            if (chance <= 2) {
                amountDiscounts[msg.sender]++;
                emit DiscountReceived(msg.sender);
            } else {
                LastToken.transfer(msg.sender, 10000);

                emit LastTokensGiven(msg.sender, 10000);
            }
        }

        delete players[msg.sender];
    }

    mapping(address => uint) public amountDiscounts;

    function viewAmountDiscountForUser(
        address _player
    ) public view returns (uint) {
        return amountDiscounts[_player];
    }

    function MintWithDiscountFromGame(uint256 _mintAmount) public payable {
        require(
            _mintAmount <= amountDiscounts[msg.sender],
            "not enough discounts"
        );
        uint requiredValue = ((Collection.cost() -
            (Collection.cost() * Collection.gameDiscount()) /
            100) * _mintAmount);
        require(msg.value == requiredValue, "incorrect msgValue");

        amountDiscounts[msg.sender] -= _mintAmount;
        Collection.mintFromGame(_mintAmount);
    }

    mapping(address => bool[5]) public RiseClaimMap;

    function claimBonus(uint _ordinal) public {
        require(
            players[msg.sender].qtyBossDefeated >= _ordinal,
            "before you need beat necessary boss"
        );
        require(_ordinal <= 3, "no more three bonuses now");

        require(
            !RiseClaimMap[msg.sender][_ordinal - 1],
            "you're already claimed this bonus"
        );

        uint chance = random(10, 125125);

        if (chance <= 2) {
            players[msg.sender].energyFactor += 10;
        } else {
            players[msg.sender].energyBalance += 1000;
        }

        RiseClaimMap[msg.sender][_ordinal - 1] = true;
        amountBonusesClaimed[msg.sender]++;
    }

    mapping(address => uint256) public amountBonusesClaimed;
    mapping(address => uint256) public amountEffectsClaimed;

    function getAvailableBonusesToClaim()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory bonusIndexes = new uint256[](
            3 - amountBonusesClaimed[msg.sender]
        );
        uint counter;

        for (uint256 i = 0; i <= 2; i++) {
            if (
                players[msg.sender].qtyBossDefeated >= i + 1 &&
                !RiseClaimMap[msg.sender][i]
            ) {
                bonusIndexes[counter] = i;
                counter++;
            }
        }

        return bonusIndexes;
    }

    function getAvailableMysticEffects()
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory effectIndexes = new uint256[](
            2 - amountEffectsClaimed[msg.sender]
        );
        uint counter;

        for (uint256 i = 3; i <= 4; i++) {
            if (
                players[msg.sender].qtyBossDefeated >= i - 1 &&
                !RiseClaimMap[msg.sender][i]
            ) {
                effectIndexes[counter] = i;
                counter++;
            }
        }

        return effectIndexes;
    }

    event BonusClaimed(uint indexed riseMapIndex);

    function claimAvailableBonuses() public {
        uint256[] memory availableBonuses = getAvailableBonusesToClaim();
        bool wasZero;

        for (uint256 i = 0; i < availableBonuses.length; i++) {
            if (availableBonuses[i] == 0 && wasZero) {
                break;
            }

            if (!wasZero && availableBonuses[i] == 0) {
                wasZero = true;
            }

            claimBonus(availableBonuses[i] + 1);
            emit BonusClaimed(i);
        }
    }

    event EffectClaimed(uint indexed riseMapIndex);

    function claimAvailableMysticEffects() public {
        uint256[] memory availableEffects = getAvailableMysticEffects();
        bool wasZero;

        for (uint256 i = 0; i < availableEffects.length; i++) {
            if (availableEffects[i] == 0 && wasZero) {
                break;
            }

            if (!wasZero && availableEffects[i] == 0) {
                wasZero = true;
            }

            claimMysticEffect(availableEffects[i] - 1);
            emit EffectClaimed(i);
        }
    }

    function claimMysticEffect(uint _ordinal) public {
        require(
            players[msg.sender].qtyBossDefeated + 1 >= _ordinal,
            "before you need beat necessary boss"
        );
        require(_ordinal >= 2 && _ordinal < 4, "out of range");

        require(
            !RiseClaimMap[msg.sender][_ordinal + 1],
            "you're already claimed this effect"
        );
        uint chance = random(10, 125125);

        if (chance <= 2) {
            players[msg.sender].energyFactor += 10;
        } else {
            players[msg.sender].energyFactor -= 1;

            amountEffectsClaimed[msg.sender]++;
            RiseClaimMap[msg.sender][_ordinal + 1] = true;
        }
    }
}
