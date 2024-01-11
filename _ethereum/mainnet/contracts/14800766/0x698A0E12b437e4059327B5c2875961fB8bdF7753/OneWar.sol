// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./Counters.sol";
import "./IOneWar.sol";
import "./OneWarGold.sol";
import "./OneWarCouncil.sol";
import "./OneWarModifier.sol";
import "./OneWarDescriptor.sol";
import "./Seeder.sol";
import "./Math.sol";

/**
 * Voyagers of the metaverse are on the lookout for land.
 * They scout for Settlements that are rich with $GOLD treasure
 * and filled with miners who will work hard to extract it,
 * one block at a time. But danger awaits them.
 * War is about to strike out. They must be weary
 * of other voyagers, thirsty for glory,
 * who desire to conquer their Settlements and
 * steal their precious $GOLD.
 *
 * Once the war begins, so does $GOLD treasure mining.
 * As soon as the voyagers have redeemed their mined $GOLD,
 * they can use it to build an army. Towers that defend
 * their Settlement's walls; catapults that destroy enemy
 * towers; and soldiers who can be used in both defense
 * and offense.
 *
 * To settle on their scouted land, voyagers pay a fee to
 * the OneWar Treasury. In return, they can become members
 * of the council that controls the Treasury, should they
 * choose to accept the honor.
 *
 * Upon settling, a voyager's new Settlement is temporarily
 * protected by a sacred sanctuary period, preventing it
 * from falling under attack. It is the duty of
 * the voyager and any appointed co-rulers to defend it,
 * thereafter.
 *
 * Let the war for glory begin!
 */

contract OneWar is IOneWar, OneWarModifier, ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter public totalSupply;
    OneWarGold public gold;
    OneWarCouncil public council;
    uint256 public warBegins;
    bool public override hasWarCountdownBegun;

    mapping(address => uint256) public scoutingEnds;
    mapping(uint256 => Settlement) public settlements;

    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant SCOUTING_COST = 1 * 10**17;
    uint256 public constant SCOUTING_DURATION = 4;
    uint256 public constant MAX_SCOUTING_DURATION = 255;

    uint256 public constant AVERAGE_SANCTUARY = 3000;
    uint256 public constant AVERAGE_TREASURE = 5000;
    uint256 public constant AVERAGE_MINERS = 100;

    uint256 public constant MINING_RATE = 4 * 10**14;

    uint32 public constant SOLDIER_COST = 1;
    uint32 public constant TOWER_COST = 6;
    uint32 public constant CATAPULT_COST = 4;

    uint32 public constant SOLDIER_STRENGTH = 1;
    uint32 public constant TOWER_STRENGTH = 20;
    uint32 public constant CATAPULT_STRENGTH = 5;

    uint8 public constant GOLD_DECIMALS = 18;
    uint256 public constant GOLD_DENOMINATION = 10**GOLD_DECIMALS;

    uint256 public constant MOTTO_CHANGE_COST = 10 * GOLD_DENOMINATION;
    uint8 public constant MOTTO_CHARACTER_LIMIT = 50;

    uint32 public constant PREWAR_DURATION = 20_000;

    modifier whenWarHasBegun() {
        require(block.number >= warBegins, "war has not begun yet");
        _;
    }

    modifier isCallerRulerOrCoruler(uint256 _settlement) {
        require(_isApprovedOrOwner(msg.sender, _settlement), "caller is not settlement ruler or co-ruler");
        _;
    }

    modifier isLocationSettled(uint256 _settlement) {
        require(_exists(_settlement), "location is not settled");
        _;
    }

    modifier whenWarCountdownHasBegun() {
        require(hasWarCountdownBegun, "war countdown has not begun");
        _;
    }

    constructor(address payable _treasury) ERC721("OneWar Settlement", "OWS") OneWarModifier(_treasury) {
        warBegins = 2**256 - 1;
        gold = new OneWarGold();
        descriptor = new OneWarDescriptor(this);
        council = new OneWarCouncil(this);
    }

    /**
     * Prior to settling, voyagers make an offering
     * to the Treasury. Scouts are subsequently
     * dispatched to seek out undiscovered land.
     * Scouting lasts 4 blocks and can be initiated before
     * the war has begun. If all 10,000 Settlements have been
     * occupied, voyagers will be unable to settle.
     */
    function scout() public payable override {
        require(msg.value >= SCOUTING_COST, "inadequate offering");
        scoutingEnds[msg.sender] = block.number + SCOUTING_DURATION;
        emit Scout(msg.sender, scoutingEnds[msg.sender]);
    }

    /**
     * Between 4 and 256 blocks after scouting has been initiated,
     * a voyager can settle into the land that was discovered by
     * the commissioned scouts. It is during this ritual
     * that the voyager gets crowned as the Settlement's ruler,
     * granted full authority over the new-found land.
     */
    function settle() public override {
        require(scoutingEnds[msg.sender] != 0, "location has not been scouted");
        require(block.number > scoutingEnds[msg.sender], "insufficient blocks since scouting began");
        require(
            block.number - scoutingEnds[msg.sender] <= MAX_SCOUTING_DURATION,
            "too many blocks since scouting began"
        );
        _tokenIds.increment();
        uint256 settlementId = _tokenIds.current();
        require(settlementId <= MAX_SUPPLY, "all land has been settled");

        uint256 seed = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(scoutingEnds[msg.sender]))));
        settlements[settlementId].genesis = block.number;
        settlements[settlementId].seed = seed;
        settlements[settlementId].founder = msg.sender;
        settlements[settlementId].glory = 0;
        settlements[settlementId].sanctuary = Seeder.generateNumber(
            AVERAGE_SANCTUARY,
            Seeder.pluck("sanctuary", seed)
        );
        settlements[settlementId].treasure =
            Seeder.generateNumber(AVERAGE_TREASURE, Seeder.pluck("treasure", seed)) *
            GOLD_DENOMINATION;
        settlements[settlementId].miners = Seeder.generateNumber(AVERAGE_MINERS, Seeder.pluck("miners", seed));
        _mint(msg.sender, settlementId);
        totalSupply.increment();
        scoutingEnds[msg.sender] = 0;

        emit Settle(msg.sender, settlementId);
    }

    /**
     * Rulers are given the right to even burn their Settlement
     * to the ground.
     */
    function burn(uint256 _settlement) public override isCallerRulerOrCoruler(_settlement) {
        _burn(_settlement);
        totalSupply.decrement();
        emit Burn(_settlement);
    }

    /**
     * It is up to the Treasury to announce when
     * the war is about to begin.
     */
    function commenceWarCountdown() public override onlyTreasury {
        require(!hasWarCountdownBegun, "war countdown has already begun");
        hasWarCountdownBegun = true;
        warBegins = block.number + PREWAR_DURATION;
    }

    /**
     * As soon as the war begins, miners get to work.
     * As they constantly dig for more $GOLD, their
     * progress can be monitored here.
     */
    function redeemableGold(uint256 _settlement) public view override isLocationSettled(_settlement) returns (uint256) {
        uint256 miningBegins = Math.max(settlements[_settlement].genesis, warBegins);
        if (block.number < miningBegins) {
            return 0;
        }

        uint256 settlementTotal = uint256(block.number - miningBegins) * settlements[_settlement].miners * MINING_RATE;
        if (settlements[_settlement].treasure < settlementTotal) {
            settlementTotal = settlements[_settlement].treasure;
        }

        return settlementTotal - settlements[_settlement].goldRedeemed;
    }

    /**
     * Rulers can redeem their mined $GOLD at any point.
     * It is only once they have redeemed their $GOLD that
     * they can spend it on their Settlement's operations.
     */
    function redeemGold(uint256[] calldata _settlements) public override whenWarHasBegun {
        uint256 totalAmount = 0;

        for (uint16 i = 0; i < _settlements.length; ++i) {
            uint256 locAmount = redeemableGold(_settlements[i]);
            settlements[_settlements[i]].goldRedeemed += locAmount;
            totalAmount += locAmount;
            require(_isApprovedOrOwner(msg.sender, _settlements[i]), "caller is not settlement ruler or co-ruler");
        }

        gold.mint(msg.sender, totalAmount);
    }

    /**
     * $GOLD can be consumed to create army units.
     * Their costs can be calculated here.
     */
    function armyCost(
        uint32 _soldiers,
        uint32 _towers,
        uint32 _catapults
    ) public pure override returns (uint256) {
        return
            uint256(SOLDIER_COST * _soldiers + TOWER_COST * _towers + CATAPULT_COST * _catapults) * GOLD_DENOMINATION;
    }

    /**
     * Any portion of a ruler's $GOLD can be consumed
     * to build an army for their Settlement.
     */
    function buildArmy(
        uint256 _settlement,
        uint32 _soldiers,
        uint32 _towers,
        uint32 _catapults
    ) public override whenWarHasBegun {
        gold.burn(msg.sender, armyCost(_soldiers, _towers, _catapults));
        settlements[_settlement].soldiers += _soldiers;
        settlements[_settlement].towers += _towers;
        settlements[_settlement].catapults += _catapults;

        emit BuildArmy(_settlement, _soldiers, _towers, _catapults);
    }

    /**
     * Rulers can relocate army units to other Settlements that
     * they may or may not control.
     */
    function moveArmy(
        uint256 _sourceSettlement,
        uint256 _destinationSettlement,
        uint32 _soldiers,
        uint32 _catapults
    ) public override whenWarHasBegun isCallerRulerOrCoruler(_sourceSettlement) {
        require(
            settlements[_sourceSettlement].soldiers >= _soldiers &&
                settlements[_sourceSettlement].catapults >= _catapults,
            "insufficient army units"
        );

        settlements[_sourceSettlement].soldiers -= _soldiers;
        settlements[_destinationSettlement].soldiers += _soldiers;
        settlements[_sourceSettlement].catapults -= _catapults;
        settlements[_destinationSettlement].catapults += _catapults;

        emit MoveArmy(_sourceSettlement, _destinationSettlement, _soldiers, _catapults);
    }

    /**
     * Rulers can dispatch multiple army units to multiple
     * Settlements, at once.
     */
    function multiMoveArmy(ArmyMove[] calldata _moves) public override whenWarHasBegun {
        for (uint256 i = 0; i < _moves.length; ++i) {
            moveArmy(_moves[i].source, _moves[i].destination, _moves[i].soldiers, _moves[i].catapults);
        }
    }

    /**
     * A Settlement's catapults and soldiers can be used
     * to attack another Settlement. If the attacking forces
     * overwhelm the defensive forces, then the Settlement under
     * attack is successfully conquered and
     * authority is transferred to the conqueror.
     *
     * Attacking catapults first attempt to take down the
     * defending towers. Subsequently, the attacking soldiers
     * target any remaining towers and lastly any defending
     * soldiers.
     *
     * A successful offensive attack must therefore be
     * orchestrated with enough catapults and soldiers to
     * annihilate all the defensive towers and soldiers.
     */
    function attack(
        uint256 _attackingSettlement,
        uint256 _defendingSettlement,
        uint32 _soldiers,
        uint32 _catapults
    )
        public
        override
        whenWarHasBegun
        isCallerRulerOrCoruler(_attackingSettlement)
        isLocationSettled(_defendingSettlement)
    {
        require(
            settlements[_attackingSettlement].soldiers >= _soldiers &&
                settlements[_attackingSettlement].catapults >= _catapults,
            "insufficient attacking army units"
        );
        require(
            Math.max(settlements[_defendingSettlement].genesis, warBegins) +
                settlements[_defendingSettlement].sanctuary <
                block.number,
            "defending settlement is in sanctuary period"
        );

        uint256 attackingSanctuaryBegins = Math.max(settlements[_attackingSettlement].genesis, warBegins);
        if (attackingSanctuaryBegins + settlements[_attackingSettlement].sanctuary > block.number) {
            settlements[_attackingSettlement].sanctuary = block.number - attackingSanctuaryBegins;
        }

        DefenderAssets memory defenderAssets;
        AttackerAssets memory attackerAssets;

        defenderAssets.soldiers = settlements[_defendingSettlement].soldiers;
        defenderAssets.towers = settlements[_defendingSettlement].towers;

        attackerAssets.soldiers = _soldiers;
        attackerAssets.catapults = _catapults;

        settlements[_attackingSettlement].soldiers -= _soldiers;
        settlements[_attackingSettlement].catapults -= _catapults;

        if (_catapults * CATAPULT_STRENGTH > TOWER_STRENGTH * settlements[_defendingSettlement].towers) {
            _catapults -= (TOWER_STRENGTH / CATAPULT_STRENGTH) * settlements[_defendingSettlement].towers;
            settlements[_defendingSettlement].towers = 0;
        } else {
            settlements[_defendingSettlement].towers -= _catapults / (TOWER_STRENGTH / CATAPULT_STRENGTH);
            _catapults = 0;
        }

        if (_soldiers * SOLDIER_STRENGTH > TOWER_STRENGTH * settlements[_defendingSettlement].towers) {
            _soldiers -= (TOWER_STRENGTH / SOLDIER_STRENGTH) * settlements[_defendingSettlement].towers;
            settlements[_defendingSettlement].towers = 0;
        } else {
            settlements[_defendingSettlement].towers -= _soldiers / (TOWER_STRENGTH / SOLDIER_STRENGTH);
            _soldiers = 0;
        }

        if (_soldiers > settlements[_defendingSettlement].soldiers) {
            _soldiers -= settlements[_defendingSettlement].soldiers;

            settlements[_defendingSettlement].glory +=
                (attackerAssets.soldiers - _soldiers) *
                SOLDIER_COST +
                (attackerAssets.catapults - _catapults) *
                CATAPULT_COST;
            settlements[_attackingSettlement].glory +=
                defenderAssets.soldiers *
                SOLDIER_COST +
                defenderAssets.towers *
                TOWER_COST;

            settlements[_defendingSettlement].soldiers = _soldiers;
            settlements[_defendingSettlement].catapults = _catapults;
            emit SuccessfulAttack(_attackingSettlement, _defendingSettlement);
            _transfer(ownerOf(_defendingSettlement), msg.sender, _defendingSettlement);
        } else {
            settlements[_defendingSettlement].soldiers -= _soldiers;
            settlements[_defendingSettlement].catapults += _catapults;

            settlements[_defendingSettlement].glory +=
                attackerAssets.soldiers *
                SOLDIER_COST +
                (attackerAssets.catapults - _catapults) *
                CATAPULT_COST;
            settlements[_attackingSettlement].glory +=
                (defenderAssets.soldiers - settlements[_defendingSettlement].soldiers) *
                SOLDIER_COST +
                (defenderAssets.towers - settlements[_defendingSettlement].towers) *
                TOWER_COST;

            emit FailedAttack(_attackingSettlement, _defendingSettlement);
        }
    }

    /**
     * Here lies the  number of blocks remaining until
     * a Settlement's sacred sanctuary period ends.
     */
    function blocksUntilSanctuaryEnds(uint256 _settlement)
        public
        view
        override
        isLocationSettled(_settlement)
        whenWarCountdownHasBegun
        returns (uint256)
    {
        uint256 sanctuaryBegins = Math.max(settlements[_settlement].genesis, warBegins);
        if (sanctuaryBegins + settlements[_settlement].sanctuary < block.number) {
            return 0;
        }

        return sanctuaryBegins + settlements[_settlement].sanctuary - block.number;
    }

    /**
     * The number of blocks remaining until the OneWar begins
     * can be viewed here.
     */
    function blocksUntilWarBegins() public view override whenWarCountdownHasBegun returns (uint256) {
        if (warBegins < block.number) {
            return 0;
        }

        return warBegins - block.number;
    }

    /**
     * Rulers may pay $GOLD to modify their
     * Settlement's motto.
     */
    function changeMotto(uint256 _settlement, string memory _newMotto)
        public
        override
        isCallerRulerOrCoruler(_settlement)
    {
        require(bytes(_newMotto).length <= MOTTO_CHARACTER_LIMIT, "motto is too long");

        gold.burn(msg.sender, MOTTO_CHANGE_COST);
        settlements[_settlement].motto = _newMotto;

        emit ChangeMotto(_settlement, _newMotto);
    }

    /**
     * The OneWar Treasury can claim their rightful offerings
     * at any time.
     */
    function redeemFundsToOneWarTreasury() external override {
        (bool redeemed, ) = treasury.call{value: address(this).balance}("");
        require(redeemed, "failed to redeem funds");
    }

    /**
     * Each Settlement has a plaque inscribed with its traits.
     */
    function tokenURI(uint256 _settlement) public view override isLocationSettled(_settlement) returns (string memory) {
        return descriptor.tokenURI(_settlement);
    }

    /**
     * Discover a particular Settlement's traits here.
     */
    function settlementTraits(uint256 _settlement)
        external
        view
        override
        isLocationSettled(_settlement)
        returns (Settlement memory)
    {
        return settlements[_settlement];
    }

    /**
     * Discover whether a voyager is a certain Settlement's
     * ruler or co-ruler.
     */
    function isRulerOrCoruler(address _address, uint256 _settlement) public view override returns (bool) {
        return _isApprovedOrOwner(_address, _settlement);
    }

    /**
     * Discover whether a specific area has been settled or
     * remains undiscovered.
     */
    function isSettled(uint256 _settlement) public view override returns (bool) {
        return _exists(_settlement);
    }
}

/**
 * War has no winners, except in honor and glory.
 * The glory of OneWar Settlements is measured in bloodshed.
 */
