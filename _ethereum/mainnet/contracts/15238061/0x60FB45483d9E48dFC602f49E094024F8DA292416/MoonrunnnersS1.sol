//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%%%%%%&&&&&&&&&&&&&&%%%%%%%%%%%%%%%&&&&&&&&&%%%%%%%&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%&&&&&&&&&&&&&&&&&%%%%%%%%%%%%&&&&&&&%%%%%%%&&&&&&&&&&&&
// &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&%%%%%%%%%&&&&&&&&&&&&&&&&&%%%%%%%%%%%%&&&&&&&%%%%%&&&&&&&&&&&&%%
// &&&&&&&&&&&&&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%&&&&&&&&&&&&&&&%%
// &&&&&&&&&&&&&&&&&&&@@@     ,,,,,****///,,,,,*******////////////////////////////////////////////////@@%%&&&&&&&&&&&&&&&%%
// &&&&&&&&&&&&&&&&&&&@@@  ########################################################################///@@&&&&&&&&&&&&&&&&&%%
// &&&&&&&&&&&&&&&&&&&@@@  ###%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%/////@@&&&&&&&&&&&&&&&%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######%%%#########%%%#########%%%#######%%##########%%##########/////@@&&&&&&&&&&&&&&&%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######%%%#########%%%#########%%%#######%%##########%%##########/////@@&&&&&&&&&&&&&&&%%%%
// &&&&&&&&&&&&&&&&&&&@@@//###%%#######%%%#########%%%#########%%%#######%%##########%%##########**///@@&&&&&&&&&&&&%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@//###%%#######%%%#########%%%#########%%%#######%%##########%%##########**///@@&&&&&&&&&&&&%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@  ###%%#######%%%#########%%%#########%%%#######%%##########%%##########**///@@&&&&&&&&&&&&%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@  ###%%#######%%%#########%%%#########%%%#######%%##########%%##########**///@@&&&&&&&&&&%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######%%%#########%%%#########%%%#######%%##########%%##########**///@@&&&&&&&&&&%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######%%%#########%%%@@@@@@@@@@@@####&@@@@@@@#######%%##########**///@@&&&&&&&&&&%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######%%%@@@@@@@@@@@@..*******///@@@@(....///@@@@@@@%%##########**///@@&&&&&&&%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%#######@@@  ..*///////****///*******///////*****#####@@##########**///@@&&&&&&&%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**###%%##&@@@@***//**,....***....,****@@@//*******************@@@#######**///@@&&&&&&&%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**(((%%&&(,,,,*******///*****///////@@,,,@@,,*////(((,,///((##///@@%%%%%**///@@&&&&&%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@**#####,,,,,//***,,,,,,,/////,,**(##(((((%%%%#(((((((../////(((((##&&&&&##(((@@&&&&&%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&&&@@@&&,,,,,*****/////**///**/////,,**#@@**###((@@#,,,,////////**/////////(##%%&&&@@&&&%%%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&@@#,,*********,....***//.......***//@@#**((#####((%@@#####****,..*******//////////,,@@@%%%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&&&@@#,,#####################(/////////@@#**((#####((%@@/////####(//#####////(#######,,@@@%%%%%%%%%%%%%%%%
// &&&&&&&&&&&&&&&@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@**/((((&&&####(((@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,#@@%%%%%%%%%%%%%%
// &&&&&&&&&&&&@@@         ,,,,,,,,*********     *****@@**/((##&&&&&##(((@@(((//************///////*****/////@@%%%%%%%%%%%%
// &&&&&&&&&&&&@@@  ,,,,,**********///////,,,,,****@@@**#######&&&&&&&&&&&&@@@##(((//////////////////////////@@%%%%%%%%%%%%
// &&&&&&&&&&&&@@@,,,,,*********///////,,,,,*******@@@@@@@&####&&&&&&&@@@@@@@@##(((//////////////////////////@@%%%%%%%%%%%%
// &&&&&&&&&&&&&&&@@%%%%%%%##########%%############@@@//##&@@@@&&&@@@@@&&##@@@%%%%%%%#########%%%#####%%%%&@@%%%%%%%%%%%%%%
// &&&&&&&&&&&&%%%@@///((%%((((((((((%%(((((((((((((((@@//(####@@@&&&&%##@@%%%####%%%(((((((((#%%(((((((((%@@%%%%%%%%%%%%%%
// &&&&&%%%%%%%%%%@@///((##((((((((((##(((((((((((((((##@@%//##&&&&&##&@@%%#####((###(((((((((###(((((((((%@@%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%@@///((##((((((((((##(((((((((((((((##((%@@//&&&##@@&%%#####((((###(((((((((###(((((((((%@@%%%%%%%%%%%%%%
// %%%%%%%&&&&&&&&@@///((##((((((((((##(((((((((((((((##(((((@@###@@%%%%%##(((((((###(((((((((###(((((((((%@@%%%%%%%%%%%%%%
// %%%&&&&&&&&&&&&@@///((##((((((((((##(((((((((((((((##(((((((@@@####%%%(((((((((###(((((((((###(((((((//%@@%%%%%%%%%%%%%%
// &&&&&&&%%%%%%%%@@///((##((((((((((##(((((((((((((((##((((((((((((((###(((((((((###(((((((((###(((((((//%@@%%%%%%%%%%%%%%
// %%%%%%%%%%%%%%%@@///((##((((((((((##(((((((((((((((##((((((((((((((###(((((((((###(((((((((###(((((((//%@@&&&&&%%%%%%%%%
// %%%%%%%%%%%%%%%@@///((##((((((((((##(((((((((((((((##((((((((((((((###(((((((((###(((((((((###(((((((//%@@@@@@@@@&&%%%%%
// %%%%%%%%%%@@%%%@@///((##((((((((((##(((((((((((((((##((((((((((((((###(((((((((###(((((((((###(((((((//%@@#######@@@@@&&
// %%%%%@@@@@//@@@    .*********//////////**************************///////*****//////////////*************//@@##########@@
// %%%@@..   **///@@@@%/////////////////////////////////////////////////////////////////////////////////@@@@@@@/////#####@@
// @@@****///*****..//%@@@@@@@/////////////////////////////////////////////////////////////////////@@@@@..,**/////////%@@@@
// .....//////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.....**********..///////
// @@@....,**.....*******..***//@@@&&&&&&&@@..,**//@@@&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@@@@(..**/////.....**//////////**
// ###@@%%&&&&&*****(((###########%@@%%%%%%%@@@@@@@%%%%%%%%%%&&&&&&&&&&&&&&&&&&&%%%%%%%@@@****/((**///**///////#####@@@@@@@
// ###&&((###%%&&&&&&&@@@(((((%%@@&###################%%%%%%%%%%%%%%%%%%%%%%%%%%##########&&&&&&&((#####%%%%%%%&&&&&%%%%%%%
// #####%%%%%%%########%%%%%%%&&%%########%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#####%%%%%%%%%%%%%%#####%%%%%%%

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ERC1155Holder.sol";
import "./IERC721A.sol";
import "./IERC1155.sol";

import "./IMoonrunners.sol";
import "./IMoonrunnersLoot.sol";
import "./BasicRNG.sol";

error AwwoooooOnly();
error CaveIsClosed();
error CallerIsNotMoonrunnerHolder();
error CallerIsNotLootHolder();
error InvalidWeaponId();
error NotApprovedForAll();
error CantFightMore();

error InvalidLegendsIdsConfig();

error ExploreIsClosed();
error CantExploreWithoutFighting();
error CantExploreMore();

error ZeroBalance();

error AwwwwooError();

contract MoonrunnersS1 is Ownable, ERC1155Holder, BasicRNG {
  using EnumerableSet for EnumerableSet.UintSet;

  event DragonBigFiraFira(address indexed owner, uint256 moonrunnerId);
  event DragonWhips(address indexed owner, uint256 moonrunnerId);
  event DragonAttack(address indexed owner, uint256 moonrunnerId, uint256 rand);
  event LootItem(address indexed owner, uint256 itemId);

  event ExploreLucky(address indexed owner, uint256 moonrunnerId, uint256 amount);
  event ExploreRescue(address indexed owner, uint256 moonrunnerId, uint256 moonrunnerRescuedId);
  event ExploreLootItem(address indexed owner, uint256 itemId);
  event ExploreLootPooPoopPeeDoo(address indexed owner, uint256 moonrunnerId);

  IMoonrunners public moonrunners;
  IMoonrunnersLoot public moonrunnersLoot;

  bool public isOpen;
  bool public isExploreOpen;

  // allowed weaponsId
  EnumerableSet.UintSet private weaponsIds;

  // moonSpeakers & moonLegendaries
  EnumerableSet.UintSet private legendsIds;

  //lootId => maxSupply
  mapping(uint256 => uint256) public maxSupplyOf;

  //moonrunnerId => fightCount
  mapping(uint256 => uint256) public fightCountOf;

  //moonrunnerId => hasExplore
  mapping(uint256 => bool) public hasExplored;

  uint256[] public capturedMR;

  uint256 private constant AWWWWOO = 0x5d423c655aa0000;
  uint256 private constant AWO = 0x16345785D8A0000;
  uint256 private availableAWWWWOO = 0xA;

  constructor(address moonrunnersAddress, address moonrunnersLootAddress) {
    moonrunners = IMoonrunners(moonrunnersAddress);
    moonrunnersLoot = IMoonrunnersLoot(moonrunnersLootAddress);

    // set allowed weaponIds
    weaponsIds.add(0); // 0: raygun
    weaponsIds.add(1); // 1: scroll
    weaponsIds.add(2); // 2: ar15
    weaponsIds.add(3); // 3: claws

    // loot maxSupply
    maxSupplyOf[4] = 10; //huge
    maxSupplyOf[5] = 523; //big
    maxSupplyOf[6] = 3100; //medium
    maxSupplyOf[7] = 6300; //small
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Entry                                    */
  /* -------------------------------------------------------------------------- */

  function fight(uint256 moonrunnerId, uint256 weaponId) external {
    if (tx.origin != _msgSender()) revert AwwoooooOnly();
    if (!isOpen) revert CaveIsClosed();
    if (!moonrunners.isApprovedForAll(_msgSender(), address(this))) revert NotApprovedForAll();
    if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
    if (moonrunnersLoot.balanceOf(_msgSender(), weaponId) == 0) revert CallerIsNotLootHolder();
    if (!weaponsIds.contains(weaponId)) revert InvalidWeaponId();
    if (fightCountOf[moonrunnerId] > 1) revert CantFightMore();

    //burn weapon
    moonrunnersLoot.controlledBurn(_msgSender(), weaponId, 1);

    //awooooo
    uint256[] memory rand = randomUint16Array(2, 10_000);

    //moonrunner attack
    uint256 lootableId = packAttack(weaponId, rand[0]);

    // dragon attack
    bool isAlive = dragonAttack(moonrunnerId, rand[1]);

    if (isAlive) {
      //mint vial
      moonrunnersLoot.mint(_msgSender(), lootableId, 1);
      emit LootItem(_msgSender(), lootableId);
    } else {
      //mint vial for explore
      moonrunnersLoot.mint(address(this), lootableId, 1);
    }
  }

  function explore(uint256 moonrunnerId) external {
    if (tx.origin != _msgSender()) revert AwwoooooOnly();
    if (!isExploreOpen) revert ExploreIsClosed();
    if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
    if (fightCountOf[moonrunnerId] < 1) revert CantExploreWithoutFighting();
    if (hasExplored[moonrunnerId]) revert CantExploreMore();

    hasExplored[moonrunnerId] = true;

    uint256[] memory rand = randomUint16Array(2, 10_000);

    doExplore(moonrunnerId, rand);
  }

  /* -------------------------------------------------------------------------- */
  /*                                   Logic                                    */
  /* -------------------------------------------------------------------------- */

  function dragonAttack(uint256 moonrunnerId, uint256 rand) internal returns (bool) {
    bool isLegendary = legendsIds.contains(moonrunnerId);

    fightCountOf[moonrunnerId] += 1;

    if (rand < 420 && !isLegendary) {
      // RIP : big fira fira
      moonrunners.burn(moonrunnerId);
      emit DragonBigFiraFira(_msgSender(), moonrunnerId);
      return false;
    } else if (rand < 520 && !isLegendary) {
      // CAPTURED : dragon whips
      capturedMR.push(moonrunnerId);
      moonrunners.transferFrom(_msgSender(), address(this), moonrunnerId);
      emit DragonWhips(_msgSender(), moonrunnerId);
      return false;
    }

    emit DragonAttack(_msgSender(), moonrunnerId, rand);
    return true;
  }

  //4 : huge | 5 : big | 6 : medium | 7 : small
  function packAttack(uint256 weaponId, uint256 rand) internal returns (uint256) {
    uint256 lootId = 7;

    if (weaponId == 0) {
      // raygun
      if (rand < 169 && moonrunnersLoot.totalSupply(4) < maxSupplyOf[4]) {
        lootId = 4;
      } else if (rand < 4700 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else {
        lootId = 6;
      }
    } else if (weaponId == 1) {
      // scroll
      if (rand < 800 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 6300 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 2) {
      // ar15
      if (rand < 300 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 3400 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    } else if (weaponId == 3) {
      // claws
      if (rand < 100 && moonrunnersLoot.totalSupply(5) < maxSupplyOf[5]) {
        lootId = 5;
      } else if (rand < 2300 && moonrunnersLoot.totalSupply(6) < maxSupplyOf[6]) {
        lootId = 6;
      }
    }

    return lootId;
  }

  /*************************************************************/

  function doExplore(uint256 moonrunnerId, uint256[] memory rand) internal {
    if (rand[0] < 75) {
      // 0.75%
      uint256 balance = address(this).balance;

      if (rand[1] < 1500 && balance >= AWWWWOO && availableAWWWWOO > 0) {
        // send AWWWWOO
        availableAWWWWOO -= 1;
        emit ExploreLucky(_msgSender(), moonrunnerId, AWWWWOO);
        (bool success, ) = payable(_msgSender()).call{value: AWWWWOO}("");
        if (!success) revert AwwwwooError();
        return;
      } else if (balance >= AWO) {
        // send AWO
        emit ExploreLucky(_msgSender(), moonrunnerId, AWO);
        (bool success, ) = payable(_msgSender()).call{value: AWO}("");
        if (!success) revert AwwwwooError();
        return;
      }
    } else if (rand[0] < 175) {
      // 1%
      if (capturedMR.length > 0) {
        //send random MR
        uint256 idx = rand[1] % capturedMR.length;
        uint256 id = capturedMR[idx];
        capturedMR[idx] = capturedMR[capturedMR.length - 1];
        capturedMR.pop();

        moonrunners.transferFrom(address(this), _msgSender(), id);
        emit ExploreRescue(_msgSender(), moonrunnerId, id);
        return;
      }
    } else if (rand[0] < 675) {
      // 5%
      //4 : huge | 5 : big | 6 : medium | 7 : small
      uint256 lootId;
      if (rand[1] < 1000 && moonrunnersLoot.balanceOf(address(this), 4) > 0) {
        lootId = 4;
      } else if (rand[1] < 3000 && moonrunnersLoot.balanceOf(address(this), 5) > 0) {
        lootId = 5;
      } else if (rand[1] < 6000 && moonrunnersLoot.balanceOf(address(this), 6) > 0) {
        lootId = 6;
      } else if (moonrunnersLoot.balanceOf(address(this), 7) > 0) {
        lootId = 7;
      }
      if (lootId > 0) {
        //send lootId
        moonrunnersLoot.safeTransferFrom(address(this), _msgSender(), lootId, 1, bytes(""));
        emit ExploreLootItem(_msgSender(), lootId);
        return;
      }
    }

    emit ExploreLootPooPoopPeeDoo(_msgSender(), moonrunnerId);
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Getters                                 */
  /* -------------------------------------------------------------------------- */

  function getFightCountBatch(uint256[] calldata moonrunnerIds) external view returns (uint256[] memory) {
    uint256[] memory fightCounts = new uint256[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) fightCounts[i] = fightCountOf[moonrunnerIds[i]];
    return fightCounts;
  }

  function getHasExploredBatch(uint256[] calldata moonrunnerIds) external view returns (bool[] memory) {
    bool[] memory _hasExplored = new bool[](moonrunnerIds.length);
    for (uint256 i; i < moonrunnerIds.length; ++i) _hasExplored[i] = hasExplored[moonrunnerIds[i]];
    return _hasExplored;
  }

  function getCapturedMR() external view returns (uint256[] memory) {
    return capturedMR;
  }

  /* -------------------------------------------------------------------------- */
  /*                                  Only Owner                                */
  /* -------------------------------------------------------------------------- */

  function setMoonrunners(address newMoonrunners) external onlyOwner {
    moonrunners = IMoonrunners(newMoonrunners);
  }

  function setMoonrunnersLoot(address newMoonrunnersLoot) external onlyOwner {
    moonrunnersLoot = IMoonrunnersLoot(newMoonrunnersLoot);
  }

  function setIsOpen(bool newIsOpen) external onlyOwner {
    if (newIsOpen && legendsIds.length() == 0) revert InvalidLegendsIdsConfig();
    isOpen = newIsOpen;
  }

  function setIsExploreOpen(bool newIsExploreOpen) external onlyOwner {
    isExploreOpen = newIsExploreOpen;
  }

  function captureMoonrunners(uint256[] memory moonrunnerIds) external onlyOwner {
    if (!moonrunners.isApprovedForAll(_msgSender(), address(this))) revert NotApprovedForAll();
    for (uint256 i; i < moonrunnerIds.length; ++i) {
      uint256 moonrunnerId = moonrunnerIds[i];
      if (moonrunners.ownerOf(moonrunnerId) != _msgSender()) revert CallerIsNotMoonrunnerHolder();
      capturedMR.push(moonrunnerId);
      moonrunners.transferFrom(_msgSender(), address(this), moonrunnerId);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                   Manage tokens holded by contract                         */
  /* -------------------------------------------------------------------------- */

  function rescueMoonruners(address account) external onlyOwner {
    uint256[] memory tokensIds = moonrunners.tokensOfOwner(address(this));
    for (uint256 i; i < tokensIds.length; ++i) {
      moonrunners.transferFrom(address(this), account, tokensIds[i]);
    }
  }

  function burnMoonruners() external onlyOwner {
    uint256[] memory tokensIds = moonrunners.tokensOfOwner(address(this));
    for (uint256 i; i < tokensIds.length; ++i) {
      moonrunners.burn(tokensIds[i]);
    }
  }

  function withdraw() external payable onlyOwner {
    uint256 balance = address(this).balance;
    if (balance == 0) revert ZeroBalance();

    (bool success, ) = payable(_msgSender()).call{value: balance}("");
    require(success, "");
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Config                                 */
  /* -------------------------------------------------------------------------- */

  function setLegendsIds(uint256[] calldata ids) external onlyOwner {
    for (uint256 i; i < ids.length; ++i) legendsIds.add(ids[i]);
  }

  /* -------------------------------------------------------------------------- */
  /*                                    Awwoooo                                 */
  /* -------------------------------------------------------------------------- */

  receive() external payable {
    //Awoooo
  }
}
