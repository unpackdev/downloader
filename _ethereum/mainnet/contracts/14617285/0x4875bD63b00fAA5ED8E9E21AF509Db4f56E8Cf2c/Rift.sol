/*

▄▄▄█████▓ ██░ ██ ▓█████     ██▀███   ██▓  █████▒▄▄▄█████▓   (for Adventurers)
▓  ██▒ ▓▒▓██░ ██▒▓█   ▀    ▓██ ▒ ██▒▓██▒▓██   ▒ ▓  ██▒ ▓▒
▒ ▓██░ ▒░▒██▀▀██░▒███      ▓██ ░▄█ ▒▒██▒▒████ ░ ▒ ▓██░ ▒░
░ ▓██▓ ░ ░▓█ ░██ ▒▓█  ▄    ▒██▀▀█▄  ░██░░▓█▒  ░ ░ ▓██▓ ░ 
  ▒██▒ ░ ░▓█▒░██▓░▒████▒   ░██▓ ▒██▒░██░░▒█░      ▒██▒ ░ 
  ▒ ░░    ▒ ░░▒░▒░░ ▒░ ░   ░ ▒▓ ░▒▓░░▓   ▒ ░      ▒ ░░   
    ░     ▒ ░▒░ ░ ░ ░  ░     ░▒ ░ ▒░ ▒ ░ ░          ░    
  ░       ░  ░░ ░   ░        ░░   ░  ▒ ░ ░ ░      ░      
          ░  ░  ░   ░  ░      ░      ░                   
                                                         
    by chris and tony
    
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC721BurnableUpgradeable.sol";

import "./Interfaces.sol";
import "./IRift.sol";

/*
    You've heard it calling... 
    Now it's time to level up your Adventure!
    Enter The Rift, and gain its power. 
    Take too much, and all suffer.
    Return what you've gained, and all benefit.. 

    --------------------------------------------
    The Rift creates a bridge between Loot derivatives and the bags that play and interact with them. 
     Bags that interact with derivatives are rewarded with XP, Levels, and Rift Charges. 

    Any derivative can read a bag's XP & Level from the Rift. This enables support for things like:
     - Dynamic items that scale with bag levels
     - Level-based Dungeon difficulties 
     - Experienced-based Lore

     more @ https://rift.live
*/

contract Rift is Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {

    event AddCharge(address indexed owner, uint256 indexed tokenId, uint16 amount, uint16 forLvl);
    event AwardXP(uint256 indexed tokenId, uint256 amount);
    event UseCharge(address indexed owner, address indexed riftObject, uint256 indexed tokenId, uint16 amount);
    event ObjectSacrificed(address indexed owner, address indexed object, uint256 tokenId, uint256 indexed bagId, uint256 powerIncrease);

    // The Rift supports 8000 Loot bags
    // 9989460 mLoot Bags (34 years worth)
    // and 2540 gLoot Bags
    IERC721 public iLoot;
    IERC721 public iMLoot;
    IERC721 public iGLoot;
    IMana public iMana;
    IRiftData public iRiftData;
    // gLoot bags must offset their bagId by adding gLootOffset when interacting
    uint32 constant glootOffset = 9997460;

    string public description;

    /*
     Rift power will decrease as bags level up and gain charges.
     Charges will create Rift Objects.
     Rift Objects can be burned into the Rift to amplify its power.
     If Rift Level reaches 0, no more charges are created.
    */
    uint32 public riftLevel;
    uint256 public riftPower;

    uint8 internal riftLevelIncreasePercentage; 
    uint8 internal riftLevelDecreasePercentage; 
    uint256 internal riftLevelMinThreshold;
    uint256 internal riftLevelMaxThreshold;
    uint256 internal riftCallibratedTime; 

    uint64 public riftObjectsSacrificed;

    mapping(uint16 => uint16) public levelChargeAward;
    mapping(address => bool) public riftObjects;
    mapping(address => bool) public riftQuests;
    mapping(address => BurnableObject) public staticBurnObjects;
    address[] public riftObjectsArr;
    address[] public staticBurnableArr;
    mapping(uint256 => ChargeData) public chargesData;
    uint256 public chargeMod; // bag creates charge every `chargeMod` levels
    uint256 public chargeRate; // bag creates a charge every `chargeRate` days

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function ownerSetDescription(string memory desc) external onlyOwner {
        description = desc;
    }

     function ownerSetManaAddress(address addr) external onlyOwner {
        iMana = IMana(addr);
    }

    function ownerSetRiftData(address addr) external onlyOwner {
        iRiftData = IRiftData(addr);
    }

    function addRiftQuest(address addr) external onlyOwner {
        riftQuests[addr] = true;
    }

    function removeRiftQuest(address addr) external onlyOwner {
        riftQuests[addr] = false;
    }

    /**
    * enables an address to mint / burn
    * @param controller the address to enable
    */
    function addRiftObject(address controller) external onlyOwner {
        riftObjects[controller] = true;
        riftObjectsArr.push(controller);
    }

    /**
    * disables an address from minting / burning
    * @param controller the address to disbale
    */
    function removeRiftObject(address controller) external onlyOwner {
        riftObjects[controller] = false;
    }

    function addStaticBurnable(address burnable, uint64 _power, uint32 _mana, uint16 _xp) external onlyOwner {
        staticBurnObjects[burnable] = BurnableObject({
            power: _power,
            mana: _mana,
            xp: _xp
        });
        staticBurnableArr.push(burnable);
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function ownerWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function ownerSetLevelChargeAward(uint16 level, uint16 charges) external onlyOwner {
        levelChargeAward[level] = charges;
    }

    function ownerSetChargeGen(uint256 _mod, uint256 _rate) external onlyOwner {
        chargeMod = _mod;
        chargeRate = _rate;
    }

    // READ

    function isBagHolder(uint256 bagId, address owner) _isBagHolder(bagId, owner) external view {}

    function getBagInfo(uint256 bagId) external view returns (RiftBagInfo memory) {
        return RiftBagInfo({
            charges: uint64(getCharges(bagId)),
            chargesUsed: chargesData[bagId].chargesUsed,
            chargesPurchased: chargesData[bagId].chargesPurchased,
            lastChargePurchased: chargesData[bagId].lastPurchase,
            xp: iRiftData.xpMap(bagId),
            level: iRiftData.getLevel(bagId)
        });
    }
    
    // WRITE

    /**
     * DEPRECATED
     * @dev purchase a Rift Charge with Mana
     * @param bagId bag that will be given the charge
     */
    // function buyCharge(uint256 bagId) external
    //     _isBagHolder(bagId, _msgSender()) 
    //     whenNotPaused 
    //     nonReentrant {
    //     ChargeData memory cd = chargesData[bagId];
    //     require(block.timestamp - cd.lastPurchase > 1 days, "Too soon"); 
    //     require(riftLevel > 0, "rift has no power");
    //     iMana.burn(_msgSender(), iRiftData.getLevel(bagId) * ((bagId < 8001 || bagId > glootOffset) ? 100 : 10));
    //     chargesData[bagId] = ChargeData({
    //         chargesPurchased: cd.chargesPurchased + 1,
    //         chargesUsed: cd.chargesUsed,
    //         lastPurchase: uint128(block.timestamp)
    //     });
    // }

    function useCharge(uint16 amount, uint256 bagId, address from) 
        _isBagHolder(bagId, from) 
        external 
        whenNotPaused 
        nonReentrant 
    {
        require(riftObjects[msg.sender], "Not of the Rift");
        require(getCharges(bagId) >= amount, "Not enough charges");
        ChargeData memory cd = chargesData[bagId];
        chargesData[bagId] = ChargeData({
            chargesPurchased: cd.chargesPurchased,
            chargesUsed: (block.timestamp - cd.lastPurchase < (chargeRate * 1 days)) ? cd.chargesUsed += amount : cd.chargesUsed += amount - 1,
            lastPurchase: (block.timestamp - cd.lastPurchase < (chargeRate * 1 days)) ? cd.lastPurchase : uint128(block.timestamp)
        });
        emit UseCharge(from, _msgSender(), bagId, amount);
    }

    // give 1 charge for first level
    // give 1 charge every chargeMod levels
    // gain 1 charge after chargeRate days (does not stack)
    function getCharges(uint256 bagId) public view returns (uint256) {
        uint256 lvl = iRiftData.getLevel(bagId);
        uint256 charges = 1;

        charges += (lvl / chargeMod);
        if (chargesData[bagId].lastPurchase >= (chargeRate * 1 days)) { charges += 1; }

        if (chargesData[bagId].chargesUsed > (charges + chargesData[bagId].chargesPurchased)) {
            return 0;
        } else {
            // purchased charges are deprecated, but still honored for anyone that purchased before deprecation
            return charges + chargesData[bagId].chargesPurchased - chargesData[bagId].chargesUsed;
        }  
    }

    /**
     * @dev increases the rift's power by burning an object into it. rewards XP. the burnt object must implement IRiftBurnable
     * @param burnableAddr address of the object that is getting burned
     * @param tokenId id of object getting burned
     * @param bagId id of bag that will get XP
     */
    function growTheRift(address burnableAddr, uint256 tokenId, uint256 bagId) _isBagHolder(bagId, _msgSender()) external whenNotPaused {
        require(riftObjects[burnableAddr], "Not of the Rift");
        require(IERC721(burnableAddr).ownerOf(tokenId) == _msgSender(), "Must be yours");
        
        ERC721BurnableUpgradeable(burnableAddr).burn(tokenId);
        _rewardBurn(burnableAddr, tokenId, bagId, IRiftBurnable(burnableAddr).burnObject(tokenId));
    }

    /**
     * @dev increases the rift's power by burning an object into it. rewards XP. 
     * @param burnableAddr address of the object that is getting burned
     * @param tokenId id of object getting burned
     * @param bagId id of bag that will get XP
     */
    function growTheRiftStatic(address burnableAddr, uint256 tokenId, uint256 bagId) _isBagHolder(bagId, _msgSender()) external whenNotPaused {
        require(IERC721(burnableAddr).ownerOf(tokenId) == _msgSender(), "Must be yours");

        IERC721(burnableAddr).transferFrom(_msgSender(), 0x000000000000000000000000000000000000dEaD, tokenId);
        _rewardBurn(burnableAddr, tokenId, bagId, staticBurnObjects[burnableAddr]);
    }

    function growTheRiftRewards(address burnableAddr, uint256 tokenId) external view returns (BurnableObject memory) {
        return IRiftBurnable(burnableAddr).burnObject(tokenId);
    }

    function _rewardBurn(address burnableAddr, uint256 tokenId, uint256 bagId, BurnableObject memory bo) internal {

        riftPower += bo.power;
        riftObjectsSacrificed += 1;     

        iRiftData.addXP(bo.xp, bagId);
        iMana.ccMintTo(_msgSender(), bo.mana);
        emit ObjectSacrificed(_msgSender(), burnableAddr, tokenId, bagId, bo.power);
    }

    function addPower(uint256 power) external whenNotPaused {
        require(riftObjects[msg.sender] == true, "Can't add power");
        riftPower += power;
    }

    // Rift Power

    /**
     * @dev rewards mana for recalibrating the Rift
     */
    function recalibrateRift() external whenNotPaused {
        require(block.timestamp - riftCallibratedTime >= 1 hours, "wait");
        if (riftPower >= riftLevelMaxThreshold) {
            // up a level
            riftLevel += 1;
            uint256 riftLevelPower = riftLevelMaxThreshold - riftLevelMinThreshold;
            riftLevelMinThreshold = riftLevelMaxThreshold;
            riftLevelMaxThreshold += riftLevelPower + (riftLevelPower * riftLevelIncreasePercentage)/100;
        } else if (riftPower < riftLevelMinThreshold) {
            // down a level
            if (riftLevel == 1) {
                riftLevel = 0;
                riftLevelMinThreshold = 0;
                riftLevelMaxThreshold = 10000;
            } else {
                riftLevel -= 1;
                uint256 riftLevelPower = riftLevelMaxThreshold - riftLevelMinThreshold;
                riftLevelMaxThreshold = riftLevelMinThreshold;
                riftLevelMinThreshold -= riftLevelPower + (riftLevelPower * riftLevelDecreasePercentage)/100;
            }
        }

        iMana.ccMintTo(msg.sender, (block.timestamp - riftCallibratedTime) / (3600) * 10 * riftLevel);
        riftCallibratedTime = block.timestamp;
    }

    // MODIFIERS

     modifier _isBagHolder(uint256 bagId, address owner) {
        if (bagId < 8001) {
            require(iLoot.ownerOf(bagId) == owner, "UNAUTH");
        } else if (bagId > glootOffset) {
            require(iGLoot.ownerOf(bagId - glootOffset) == owner, "UNAUTH");
        } else {
            require(iMLoot.ownerOf(bagId) == owner, "UNAUTH");
        }
        _;
    }
}