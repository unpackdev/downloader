//SPDX-License-Identifier: No License
pragma solidity 0.8.7;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./YetiTown.sol";
import "./FRXST.sol";
import "./Timestamp.sol";
import "./IVRF.sol";
import "./Whitelist.sol";
import "./Initializable.sol";

contract YetiGameLogic is  Ownable, IERC721Receiver, rarityCheck, Initializable, Pausable {

    YetiTown public yeti;
    FRXST public frxst;
    rarityCheck public rs;
    IVRF public RandomnessEngine;
    address treasury;

    struct Stake {
        uint16 tokenId;
        uint80 value;
        uint8 activityId;
        address owner;
        uint80 stakeTime;
    }

    struct InjuryStake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    struct initGame {
        uint randomValue;
    }


    bytes32 public getSignerStore;
    event TokenStaked(address owner, uint tokenId, uint8 activityId, uint value);
    event YetiClaimed(uint tokenId, uint earned, bool unstaked);
    event Injury(uint tokenId, uint80 injuredblock);
    event Stolen(uint tokenId);
    event Healing(uint tokenId, address healer, uint cost);
    event Log(address, uint16, uint8);

    mapping (address => uint[]) public stakedToken;
    mapping (uint => uint) public  tokenToPosition;
    mapping (uint => bool) public initiateGame;
    mapping(uint => Stake) public palace;
    mapping(uint => Stake) public fighters;
    Stake[] public fighterArray;
    mapping(uint => uint) public fighterIndices;
    mapping (uint => initGame) public randomIndex;
    mapping(uint => InjuryStake) public hospital;
    mapping(uint256 => uint256) public experience;
    mapping(uint => uint8) public levels;
    mapping(uint256 => uint256) public tokenRarity;

    uint public MINIMUM_TO_EXIT = 2 days;
    uint public INJURY_TIME = 1 days;
    uint public GATHERING_TAX_RISK_PERCENTAGE = 50;
    uint public HUNTING_INJURY_RISK_PERCENTAGE = 500;
    uint public FIGHTING_STOLEN_RISK_PERCENTAGE = 100;
    uint public GENERAL_FRXST_TAX_PERCENTAGE = 10;
    uint public GATHERING_FRXST_TAX_PERCENTAGE = 50;
    uint public rewardCalculationDuration = 1 days;
    uint public HEALING_COST = 500 * 1e18;
    uint public LEVEL_UP_COST_MULTIPLIER = 100;

    uint public totalYetiStakedGathering;
    uint public totalYetiStakedHunting;
    uint public totalYetiStakedFighting;

    uint[][] public rates = [
    [50, 60, 4],
    [90, 135, 10],
    [130, 195, 26]
    ];

    uint[][] public exprates = [
    [80,100,120],
    [96,120,144],
    [120,150,180]
    ];

    uint[] public yetiMultiplier = [100, 120, 150];
    uint[] levelCost = [0, 48, 210, 512, 980, 2100, 3430, 4760, 6379, 8313];
    uint[] levelExp = [0, 50, 200, 450, 800, 1600, 2450, 3200, 4050, 5000];

    bool public rescueEnabled = false;
    address designatedSigner = 0x2141fc90F4d8114e8778447d7c19b5992F6A0611;

    // Getters
    function GetTotalYetiStaked() public view returns (uint) {
        return totalYetiStakedGathering + totalYetiStakedHunting + totalYetiStakedFighting;
    }
    function getStakedTokens(address _user) external view returns(uint[] memory) {
        return stakedToken[_user];
    }

    // Setters
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setyetiMultiplier(uint[] memory _yetiMultiplier) external onlyOwner {
        yetiMultiplier = _yetiMultiplier;
    }

    function setlevelCost(uint[] memory _levelCost) external onlyOwner {
        levelCost = _levelCost;
    }

    function setLevelExp(uint[] memory _levelExp) external onlyOwner {
        levelExp = _levelExp;
    }

    function setRewardCalculationDuration(uint _amount) external onlyOwner {
        rewardCalculationDuration = _amount;
    }

    function setVRF (address _vrf) external onlyOwner {
        RandomnessEngine = IVRF(_vrf);
    }

    function SetFrxstRates(uint[][] memory _rates) public onlyOwner {
        rates = _rates;
    }

    function SetGeneralTaxPercentage(uint _tax) external onlyOwner {
        GENERAL_FRXST_TAX_PERCENTAGE = _tax;
    }

    function SetGatherTaxPercentage(uint _tax) external onlyOwner {
        GATHERING_FRXST_TAX_PERCENTAGE = _tax;
    }
   
    function SetLevelUpCostMultiplier(uint _multiplier) external onlyOwner {
        LEVEL_UP_COST_MULTIPLIER = _multiplier;
    }

    function SetExpRates(uint[][] memory _exprates) external onlyOwner {
        exprates = _exprates;
    }

    function SetDesignatedSigner(address newSigner) external onlyOwner{
        designatedSigner = newSigner;
    }

    function gatheringFRXSTRisk(uint _new) external onlyOwner{
        GATHERING_TAX_RISK_PERCENTAGE = _new;
    }

    function huntingInjuryRisk(uint _new) external onlyOwner{
        HUNTING_INJURY_RISK_PERCENTAGE = _new;
    }

    function fightingStolenRisk(uint _new) external onlyOwner{
        FIGHTING_STOLEN_RISK_PERCENTAGE = _new;
    }

    function healCostSetter (uint cost) external onlyOwner {
        HEALING_COST = cost;
    }

    // In days
    function SetInjuryTime(uint _seconds) external onlyOwner {
        INJURY_TIME = _seconds;
    }
    // In days
    function SetMinimumClaimTime(uint _seconds) external onlyOwner {
        MINIMUM_TO_EXIT = _seconds;
    }

    // In ether
    function SetHealingCost(uint _healingcost) external onlyOwner {
        LEVEL_UP_COST_MULTIPLIER = _healingcost * 1e18;
    }

    function SetRescueEnabled(bool _rescue) external onlyOwner {
        rescueEnabled = _rescue;
    }

    // Game Functionality
    function _addExp(uint tokenId, uint amount) internal {
        experience[tokenId] += amount;
    }

    function newFightingHonour(uint level) internal view returns(uint){
        uint temp = FIGHTING_STOLEN_RISK_PERCENTAGE;
        temp -= 5*(level-1);
        return temp;
    }

    function newHuntingInjuryRisk(uint level) internal view returns(uint){
        uint temp = HUNTING_INJURY_RISK_PERCENTAGE;
        temp -= 25*(level-1);
        return temp;
    }

    function newGatheringTax(uint level) internal view returns(uint){
        uint temp = GATHERING_TAX_RISK_PERCENTAGE;
        temp-= 2*(level-1);
        return temp;
    }

    function initialize()
    public
    virtual
    override(Pausable, Ownable)
    initializer
    {
        Pausable.initialize();
        Ownable.initialize();
    }

    function init(
        address _yeti,
        address _frxst,
        address _treasury,
        address _rs,
        address _vrf)
    virtual
    public
    onlyOwner
    {
        if (_yeti != address(0)) {
            yeti = YetiTown(_yeti);
        }
        if (_frxst != address(0)) {
            frxst = FRXST(_frxst);
        }
        if (_treasury != address(0)) {
            treasury = _treasury;
        }
        if (_rs != address(0)) {
            rs = rarityCheck(_rs);
        }
        if (_vrf != address(0)) {
            RandomnessEngine = IVRF(_vrf);
        }
    }

    function initiateGameAt (Rarity[] memory rarity) external {
        for (uint i=0; i<rarity.length;i++) {
            Rarity memory currentRarity = rarity[i];
            require (getSigner(currentRarity) == designatedSigner,"Not valid signer");
            tokenRarity[currentRarity.tokenId] = currentRarity.rarityIndex;
            initiateGame[currentRarity.tokenId] = true;
        }
    }

    function levelup(uint tokenId) external whenNotPaused {
        require (initiateGame[tokenId]==true,'Game Not Initiated');
        require(fighters[tokenId].tokenId != tokenId, "Can't level up while fighting");
        require(palace[tokenId].tokenId != tokenId, "Can't level up while staked");
        require(hospital[tokenId].tokenId != tokenId, "Can't level up while injured");
        require(levels[tokenId] > 0 && levels[tokenId] < 10, "Can exceed level ran");
        require(frxst.balanceOf(msg.sender) >= levelCost[levels[tokenId]], "Insufficient FRXST");
        frxst.burn(_msgSender(), levelCost[levels[tokenId]]* 1 ether);
        experience[tokenId] -= levelExp[levels[tokenId]];
        levels[tokenId] += 1;
    }

    function addManyToPalace(address account, uint[] memory tokenIds, uint8 activityId) external {
        require (activityId < 3, "Not valid activity id");
        require(account == _msgSender() || _msgSender() == address(yeti), "DONT GIVE YOUR TOKENS AWAY");
        for (uint i = 0; i < tokenIds.length; i++) {
            require (initiateGame[tokenIds[i]]==true,'Game Not Initiated');
            require(fighters[tokenIds[i]].tokenId != tokenIds[i], "fighting yeti");
            require(palace[tokenIds[i]].tokenId != tokenIds[i], "staked yeti");
            require(hospital[tokenIds[i]].tokenId != tokenIds[i], "injured yeti");
            uint index = RandomnessEngine.getCurrentIndex();
            randomIndex[tokenIds[i]] = initGame(index);
            if (_msgSender() != address(yeti)) {
                require(yeti.ownerOf(tokenIds[i]) == msg.sender, "AIN'T YO TOKEN");
                yeti.transferFrom(_msgSender(), address(this), tokenIds[i]);
                tokenToPosition[tokenIds[i]] = stakedToken[msg.sender].length;
                stakedToken[msg.sender].push(tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue;
            }
            if (levels[tokenIds[i]] == 0) {
                levels[tokenIds[i]] = 1;
                experience[tokenIds[i]] = 0;
            }
            if (activityId == 2) {
                _addYetiToFighting(account, tokenIds[i], activityId);
            } else {
                _addYetiToPalace(account, tokenIds[i], activityId);
            }
        }
    }

    function popToken(uint tokenId, address _user) internal {
        uint[] storage currentMap = stakedToken[_user];
        uint lastToken = currentMap[currentMap.length-1];
        tokenToPosition[lastToken] = tokenToPosition[tokenId];
        currentMap[tokenToPosition[lastToken]] = lastToken;
        stakedToken[_user].pop();
    }

    function _addYetiToFighting(address account, uint tokenId, uint8 activityId) internal  {

        fighterIndices[tokenId] = totalYetiStakedFighting;
        Stake memory fs = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        activityId: activityId,
        value: uint80(block.timestamp),
        stakeTime: uint80(block.timestamp)
        });
        fighters[tokenId] = fs;
        fighterArray.push(fs);
        fighterIndices[tokenId] = fighterArray.length - 1;
        totalYetiStakedFighting += 1;
        emit TokenStaked(account, tokenId, activityId, block.timestamp);
    }

    function _addYetiToPalace(address account, uint tokenId, uint8 activityId) internal  { //whenNotPaused

        palace[tokenId] = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        activityId: activityId,
        value: uint80(block.timestamp),
        stakeTime: uint80(block.timestamp)
        });
        if (activityId == 0) {
            totalYetiStakedGathering += 1;
        } else if (activityId == 1) {
            totalYetiStakedHunting += 1;
        }
        emit TokenStaked(account, tokenId, activityId, block.timestamp);
    }

    function ClaimSickYeti(uint tokenId) public {
        _claimYetiFromHospital(tokenId, false);
    }

    function claimMany(uint16[] calldata tokenIds, bool unstake) external whenNotPaused  {//whenNotPaused
        uint owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            require (initiateGame[tokenIds[i]]==true,'Game Not Initiated');
            require(fighters[tokenIds[i]].tokenId == tokenIds[i] || palace[tokenIds[i]].tokenId == tokenIds[i], "Yeti is not staked");
            owed += _claimYeti(tokenIds[i], unstake);
        }
        require(owed > 0, "Claiming before 1 day");
        frxst.mint(_msgSender(), owed);
    }

    function _payYetiTax(uint amount) internal {
        frxst.mint(treasury, amount);
    }

    function heal_cost(uint tokenId) internal view returns (uint) {
        return 2*150* yetiMultiplier[tokenRarity[tokenId]]/100;
    }

    function Heal(uint tokenId) external {
        require(hospital[tokenId].value + INJURY_TIME > block.timestamp, "YOU ARE NOT INJURED");
            if (frxst.transferFrom(msg.sender, treasury, heal_cost(tokenId) * 1 ether)) {
                _claimYetiFromHospital(tokenId, true);
                emit Healing(tokenId, msg.sender,heal_cost(tokenId));
            }
    }

    function _claimYetiFromHospital(uint tokenId, bool healed) internal {
        InjuryStake memory stake = hospital[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(healed || (block.timestamp - stake.value > INJURY_TIME), "Yeti not healed yet!");
        yeti.safeTransferFrom(address(this), _msgSender(), tokenId, "");
        popToken(tokenId, msg.sender);
        delete tokenToPosition[tokenId];
        delete hospital[tokenId];
    }

    function _claimYetiFromPalace(uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        Stake memory stake = palace[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require (initiateGame[tokenId]==true,'Game Not Initiated');
        require(!( unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT ), "Need two days of Frxst before claiming");
        uint c = tokenRarity[tokenId];
        uint hourly;
        if (stake.activityId == 1) {
            hourly = rates[c][stake.activityId] * 1 ether;
            hourly = hourly + hourly*(levels[tokenId]-1)/10;
        } else{
            hourly = rates[c][stake.activityId] *1 ether;
            hourly = hourly + hourly*(levels[tokenId]-1)/10;
        }
        if (unstake) {
            uint mod = (block.timestamp - stake.value) /rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            uint owedExp = ((block.timestamp - stake.stakeTime)/rewardCalculationDuration)* exprates[c][stake.activityId];
            if (stake.activityId == 0) {
                initGame storage init = randomIndex[tokenId];
                uint rand = RandomnessEngine.initiateRandomness(tokenId,init.randomValue);
                require (rand > 0 , "Randomness not received");
                init.randomValue = RandomnessEngine.getCurrentIndex();
                if (rand % 100 < GATHERING_FRXST_TAX_PERCENTAGE)
                {
                    uint amountToPay = newGatheringTax(levels[tokenId]);
                    _payYetiTax(owedFrxst * amountToPay / 100);
                    owedFrxst = owedFrxst * (100 - amountToPay) / 100;
                }
                yeti.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                popToken(tokenId, msg.sender);
                delete tokenToPosition[tokenId];
                if (experience[tokenId] < levelExp[levels[tokenId]]) {
                    if(owedExp > levelExp[levels[tokenId]]) {
                        owedExp = levelExp[levels[tokenId]] - experience[tokenId];
                    }
                    experience[tokenId] += owedExp;
                }
            }
            // Check Injury
            else if (stake.activityId == 1) {
                initGame storage init = randomIndex[tokenId];
                uint rand = RandomnessEngine.initiateRandomness(tokenId,init.randomValue);
                require (rand>0,"Randomness not received");
                init.randomValue = RandomnessEngine.getCurrentIndex();
                if (rand % 1000 < newHuntingInjuryRisk(levels[tokenId])) {
                    owedExp = owedExp/2;
                    if (experience[tokenId] < levelExp[levels[tokenId]]) {
                        if(owedExp > levelExp[levels[tokenId]]) {
                            owedExp = levelExp[levels[tokenId]] - experience[tokenId];
                        }
                        experience[tokenId] += owedExp;
                    }
                    hospital[tokenId] = InjuryStake({
                    owner: _msgSender(),
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                    });
                    emit Injury(tokenId, uint80(block.timestamp));
                } else {
                    yeti.safeTransferFrom(address(this), _msgSender(), tokenId, "");
                    popToken(tokenId, msg.sender);
                    delete tokenToPosition[tokenId];
                    if (experience[tokenId] < levelExp[levels[tokenId]]) {
                        if(owedExp > levelExp[levels[tokenId]]) {
                            owedExp = levelExp[levels[tokenId]] - experience[tokenId];
                        }
                        experience[tokenId] += owedExp;
                    }
                }
                totalYetiStakedHunting -= 1;
            }
            delete palace[tokenId];
        }
        else {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            _payYetiTax(owedFrxst * GENERAL_FRXST_TAX_PERCENTAGE / 100);
            owedFrxst = owedFrxst * (100 - GENERAL_FRXST_TAX_PERCENTAGE) / 100;

            palace[tokenId] = Stake({
            owner: _msgSender(),
            tokenId: uint16(tokenId),
            activityId: stake.activityId,
            value: uint80(block.timestamp),
            stakeTime: stake.stakeTime
            });
        }
        emit YetiClaimed(tokenId, owedFrxst, unstake);
    }

    function _claimYetiFromFighting(uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        Stake memory stake = fighters[tokenId];
        require (initiateGame[tokenId]==true,'Game Not Initiated');
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S FROST");
        uint hourly = rates[tokenRarity[tokenId]][stake.activityId] * levels[tokenId]*1 ether;
        hourly = hourly + hourly* (levels[tokenId]-1)/10;
        if (unstake) {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration;
            owedFrxst =  (hourly * mod);
            uint owedExp = ((block.timestamp - stake.stakeTime)/rewardCalculationDuration)* exprates[tokenRarity[tokenId]][stake.activityId];
            initGame storage init = randomIndex[tokenId];
            uint rand = RandomnessEngine.initiateRandomness(tokenId,init.randomValue);
            require (rand > 0,"Randomness not received");
            Stake memory lastStake = fighterArray[fighterArray.length - 1];
            if (experience[tokenId] < levelExp[levels[tokenId]]) {
                if(owedExp > levelExp[levels[tokenId]]) {
                    owedExp = levelExp[levels[tokenId]] - experience[tokenId];
                }
                experience[tokenId] += owedExp;
            }
            if (rand % 1000 < newFightingHonour(levels[tokenId])) {
                init.randomValue = RandomnessEngine.getCurrentIndex();
                address recipient = selectRecipient(uint(keccak256(abi.encodePacked(rand,'constantValue'))));
                yeti.safeTransferFrom(address(this), recipient, tokenId, "");
                popToken(tokenId, msg.sender);
                delete tokenToPosition[tokenId];
                experience[tokenId] = 0;
                levels[tokenId] = 1;
                emit Stolen(tokenId);
            } else {
                yeti.safeTransferFrom(address(this), msg.sender, tokenId, "");
                popToken(tokenId, msg.sender);
                delete tokenToPosition[tokenId];
            }
            fighterArray[fighterIndices[tokenId]] = lastStake;
            fighterIndices[lastStake.tokenId] = fighterIndices[tokenId];
            fighterArray.pop();
            delete fighterIndices[tokenId];
            delete fighters[tokenId];
            totalYetiStakedFighting -= 1;
            delete fighters[tokenId];
        } else {
            uint mod = (block.timestamp - stake.value) / rewardCalculationDuration ;
            owedFrxst =  (hourly * mod);
            uint owedExp = mod * exprates[tokenRarity[tokenId]][stake.activityId];
            _payYetiTax(owedFrxst * GENERAL_FRXST_TAX_PERCENTAGE / 100);
            owedFrxst = owedFrxst * (100 - GENERAL_FRXST_TAX_PERCENTAGE) / 100;
            fighters[tokenId] = Stake({
            owner: _msgSender(),
            tokenId: uint16(tokenId),
            activityId: stake.activityId,
            value: uint80(block.timestamp),
            stakeTime: stake.stakeTime
            });
        }
        emit YetiClaimed(tokenId, owedFrxst, unstake);
    }

    function _claimYeti(uint tokenId, bool unstake) internal returns (uint owedFrxst) {
        if (fighters[tokenId].tokenId != tokenId) {
            return _claimYetiFromPalace(tokenId, unstake);
        } else {
            return _claimYetiFromFighting(tokenId, unstake);
        }
    }

    function selectRecipient(uint seed) internal view returns (address) {
        address thief = randomYetiFighter(seed); // 144 bits reserved for trait selection
        if (thief == address(0x0)) return _msgSender();
        return thief;
    }

    function randomYetiFighter(uint seed) internal view returns (address) {
        require(fighterArray.length>0, "Array Size 0"); //require statement added here
        if (totalYetiStakedFighting == 0) return address(0x0);
        return fighterArray[seed % fighterArray.length].owner;
    }

    /**
  * emergency unstake tokens
  * @param tokenIds the IDs of the tokens to claim earnings from
    */

    function rescue(uint[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint tokenId;
        Stake memory stake;
        Stake memory lastStake;

        for (uint i = 0; i < tokenIds.length; i++) {
            require (initiateGame[i]==true,'Game Not Initiated');
            tokenId = tokenIds[i];
            if (fighters[tokenId].tokenId != tokenId) {
                stake = palace[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                yeti.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Yeti
                delete palace[tokenId];
                if (stake.activityId == 1) {
                    totalYetiStakedGathering -= 1;
                } else {
                    totalYetiStakedHunting -= 1;
                }
                emit YetiClaimed(tokenId, 0, true);
            } else {
                stake = fighterArray[fighterIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                yeti.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Yeti
                lastStake = fighterArray[fighterArray.length - 1];
                totalYetiStakedFighting -= 1;
                fighters[fighterIndices[tokenId]] = lastStake; // Shuffle last Yeti to current position
                fighterIndices[lastStake.tokenId] = fighterIndices[tokenId];
                fighterArray.pop(); // Remove duplicate
                delete fighterIndices[tokenId]; // Delete old mapping
                delete fighters[tokenId]; // Delete old mapping
                emit YetiClaimed(tokenId, 0, true);
            }
        }
    }

    function onERC721Received(
        address,
        address from,
        uint,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Palace directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}
