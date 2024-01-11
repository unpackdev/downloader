// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "./IERC20.sol";
import "./IERC721.sol";
import "./OwnableUpgradeable.sol";
import "./MerkleProof.sol";

abstract contract IGemies is IERC20 {
    function registerAttack(address victim, uint256 amount) external {}
}

contract IStakingProvider {
    function getDailyReward(address user) external view returns (uint256) {}
    function hasDebt(address user) external view returns (bool) {}
    function getHouseBalance(address owner) external view returns (uint256) {}
}

contract IYogieItem {
    function balanceOf(address user) external view returns (uint256) {}
}

abstract contract IYogies is IERC721 {
    function vaultStartPoint() external view returns (uint256) {}
    function viyStartPoint() external view returns (uint256) {}
    function getTotalStakedYogies(address user) external view returns (uint256) {}
}

contract IRandomizer {
    function getRandomNumber(address attacker, address victim) external view returns (uint256) {}
}

contract YogiesAttack is OwnableUpgradeable {

    bool public attackEnabled;

    /** === Ecosystem Contracts === */
    IStakingProvider public stakingProvider;
    IGemies public gemies;
    IYogies public yogies;
    IYogieItem public pets;
    IYogieItem public house;
    IRandomizer public randomizer;

    /** === Attack variables === */
    mapping(address => uint256) public userToCooldown;
    mapping(address => uint256) public userToAttackCooldown;
    uint256 public maxStealPercentage;
    uint256 public minStealPercentage;
    uint256 public victimCooldown;
    uint256 public attackerCooldown;

    /** === Tracking === */
    mapping(address => uint256) public userToStolen;

    uint256 public vaultMaxStealPercentage;
    uint256 public vaultMinStealPercentage;

    uint256 public viyMaxStealPercentage;
    uint256 public viyMinStealPercentage;

    /** === Events === */
    event Attack(address indexed attacker, address indexed victim, uint256 indexed stolen, uint256 percentage);

    constructor(
        address _staking,
        address _gemies,
        address _yogies,
        address _pets,
        address _house,
        address _randomizer
    ) {}

     function initialize(
        address _staking,
        address _gemies,
        address _yogies,
        address _pets,
        address _house,
        address _randomizer
    ) public initializer {
        __Ownable_init();

        stakingProvider = IStakingProvider(_staking);
        gemies = IGemies(_gemies);
        yogies = IYogies(_yogies);
        pets = IYogieItem(_pets);
        house = IYogieItem(_house);
        randomizer = IRandomizer(_randomizer);

        maxStealPercentage = 50;
        minStealPercentage = 25;
        victimCooldown = 1 hours;
        attackerCooldown = 1 days;
    }

    function _validateVaultYogies(uint256 yogieId) internal view returns (bool) {
        uint256 vaultStartPoint = yogies.vaultStartPoint();
        uint256 viyStartPoint = yogies.viyStartPoint();
        return vaultStartPoint != 0 && yogieId >= vaultStartPoint && yogieId < viyStartPoint;
    }

    function _validateVIY(uint256 yogieId) internal view returns (bool) {
        uint256 viyStartPoint = yogies.viyStartPoint();
        return yogieId >= viyStartPoint;
    }

    function attack(address victim, uint256 providedYogie) external {
        require(attackEnabled, "Attacks disabled");
        require(yogies.balanceOf(msg.sender) > 0, "Sender not yogies owner");
        require(userToCooldown[victim] < block.timestamp, "Victim is in cooldown");
        require(userToAttackCooldown[msg.sender] < block.timestamp, "Attacker is in cooldown");
        require(pets.balanceOf(victim) == 0, "Victim is protected");

        //if (house.balanceOf(msg.sender) == 0) {
        //    require(house.balanceOf(victim) == 0, "Cannot attack victim with house");
        //}

        uint256 minSteal = minStealPercentage;
        uint256 maxSteal = maxStealPercentage;

        if (_validateVaultYogies(providedYogie) && yogies.ownerOf(providedYogie) == msg.sender) {
            minSteal = vaultMinStealPercentage;
            maxSteal = vaultMaxStealPercentage;
        } else if (_validateVIY(providedYogie) && yogies.ownerOf(providedYogie) == msg.sender) {
            minSteal = viyMinStealPercentage;
            maxSteal = viyMaxStealPercentage;
        }

        uint256 randomNumber = randomizer.getRandomNumber(msg.sender, victim);
        uint256 stealPercentage = (randomNumber % (maxSteal  - minSteal + 1)) + maxSteal; // num between min and max steal
        uint256 amountToSteal = stakingProvider.getDailyReward(victim) * stealPercentage / 100;

        require(amountToSteal > 0, "No gemies to steal");

        userToStolen[msg.sender] += amountToSteal;

        gemies.registerAttack(victim, amountToSteal);
        userToCooldown[victim] = block.timestamp + (victimCooldown * stealPercentage);
        userToAttackCooldown[msg.sender] = block.timestamp + attackerCooldown;

        emit Attack(msg.sender, victim, amountToSteal, stealPercentage);
    }

    /** === Owner === */
    function setStakingProvider(address _addr) external onlyOwner {
        stakingProvider = IStakingProvider(_addr);
    }

    function setGemies(address _addr) external onlyOwner {
        gemies = IGemies(_addr);
    }

    function setYogiesPets(address _addr) external onlyOwner {
        pets = IYogieItem(_addr);
    }

    function setYogiesHouse(address _addr) external onlyOwner {
        house = IYogieItem(_addr);
    }

    function setYogies(address _addr) external onlyOwner {
        yogies = IYogies(_addr);
    }

    function setRandomizer(address _addr) external onlyOwner {
        randomizer = IRandomizer(_addr);
    }

    function setUserCooldown(address _user, uint256 cooldown) external onlyOwner {
        userToCooldown[_user] = cooldown;
    }

    function setAttackEnabled(bool _enabled) external onlyOwner {
        attackEnabled = _enabled;
    }

    function setYogiesStealPercentages(uint256 min, uint256 max) external onlyOwner {
        minStealPercentage = min;
        maxStealPercentage = max;
    }

    function setVaultStealPercentages(uint256 min, uint256 max) external onlyOwner {
        vaultMinStealPercentage = min;
        vaultMaxStealPercentage = max;
    }

    function setViyStealPercentages(uint256 min, uint256 max) external onlyOwner {
        viyMinStealPercentage = min;
        viyMaxStealPercentage = max;
    }

    function setVictimCooldown(uint256 cooldown) external onlyOwner {
        victimCooldown = cooldown;
    }

    function setAttackerCooldown(uint256 cooldown) external onlyOwner {
        attackerCooldown = cooldown;
    }

    function setAttackCooldownOfUser(address user, uint256 value) external onlyOwner {
        userToAttackCooldown[user] = value;
    }
}