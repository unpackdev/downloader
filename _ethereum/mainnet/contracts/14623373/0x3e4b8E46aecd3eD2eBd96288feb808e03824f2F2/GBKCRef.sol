// SPDX-License-Identifier: MIT
/*

Green Bud Killers Club — RefSystem

===========================                    .                          =========================
===========================                    M                          =========================
===========================                   dM                          =========================
===========================                   MMr                         =========================
===========================                  4MMML                  .     =========================
===========================                  MMMMM.                xf     =========================
===========================  .              "MMMMM               .MM-     =========================
===========================   Mh..          +MMMMMM            .MMMM      =========================
===========================   .MMM.         .MMMMML.          MMMMMh      =========================
===========================    )MMMh.        MMMMMM         MMMMMMM       =========================
===========================     3MMMMx.     'MMMMMMf      xnMMMMMM"       =========================
===========================     '*MMMMM      MMMMMM.     nMMMMMMP"        =========================
===========================       *MMMMMx    "MMMMM\    .MMMMMMM=         =========================
===========================        *MMMMMh   "MMMMM"   JMMMMMMP           =========================
===========================          MMMMMM   3MMMM.  dMMMMMM            .=========================
===========================           MMMMMM  "MMMM  .MMMMM(        .nnMP"=========================
===========================..          *MMMMx  MMM"  dMMMM"    .nnMMMMM*  =========================
=========================== "MMn...     'MMMMr 'MM   MMM"   .nMMMMMMM*"   =========================
===========================  "4MMMMnn..   *MMM  MM  MMP"  .dMMMMMMM""     =========================
===========================    ^MMMMMMMMx.  *ML "M .M*  .MMMMMM**"        =========================
===========================       *PMMMMMMhn. *x > M  .MMMM**""           =========================
===========================          ""**MMMMhx/.h/ .=*"                  =========================
===========================                   .3P"%....             ===============================
==============================             nP"     "*M*=         ==================================

*/
pragma solidity ^0.8.9;

import "./Context.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract GBKCRef is Context, ERC721A, Ownable {
    struct User {
        address payable parent; //refferer for this address
        uint totalReward; //Total reward
        uint children;   //Counter
    }

    mapping(address => User) public users;

    event childRegistered(address child, address parent);
    event PaidToDaddy(address from, address to, uint value, uint level);



    uint256 public royalty = 10; //10%
    uint256 public maxLevels = 3; //3 lvl of refs
    uint256 public baseMultiplier = 2;
    uint256 public totalRoyalties = 1;

    enum RewardsFor { HOLDERS, ALL }
    RewardsFor public rewardsfor = RewardsFor.HOLDERS;

     constructor(string memory _name, string memory _symbol, uint _royaltyPercent) ERC721A(_name, _symbol) {
         setRoyaltyPercent(_royaltyPercent);
     }

    function setMaxLevels(uint256 _level) external onlyOwner {
        maxLevels = _level;
    }

    function setBaseMultiplier(uint256 _multiplier) external onlyOwner {
        baseMultiplier = _multiplier;
    }

    function setRoyaltyPercent(uint256 _royalty) public onlyOwner {
       require(_royalty > 5, "Royalty must be gt 5%");
        royalty = _royalty;
    }

    function setRefSystem(uint newState) external onlyOwner {
        rewardsfor = RewardsFor(newState);
    }

    function totalRewarded() public view returns(uint256) {
        return totalRoyalties;
    }
    function hasParent(address addr) public view returns(bool) {
        return users[addr].parent != address(0);
    }

    function getMyParent() public view returns(address) {
        return users[_msgSender()].parent;
    }

    function getMyRefCount() public view returns(uint256) {
        return users[_msgSender()].children;
    }

    function getMyReward() public view returns(uint256) {
        return users[_msgSender()].totalReward;
    }

    function addParent(address payable _parent) internal {
        require(users[_msgSender()].parent == address(0), "Already have refferer");
        require(_parent != address(0), "nullAddress can't be your daddy");
        require(!isDeathLoop(_parent, _msgSender()), "Deathloop");
        

        users[_msgSender()].parent = _parent;
        users[_parent].children += 1;
        emit childRegistered(_msgSender(), _parent);
    }
  
    function isDeathLoop(address _parent, address _child) internal view returns(bool){
        address parent = _parent;
        for (uint i; i < maxLevels; i++) {
            if (parent == address(0)) break; 
            if (parent == _child)  return true;
            parent = users[parent].parent;
        }

        return false;
    }

    function payToParents(uint256 value) internal {
        User memory executor = users[_msgSender()];
        uint256 rewardValue = value;
        uint256 cycleReward = 1;
        //uint256 divider = 1;
        uint256 multiplier = 1;
         for (uint i; i < maxLevels; i++) {
             address payable parentAddr = executor.parent;
             User storage parent = users[executor.parent];
             if(parentAddr == address(0)) break;

             //reward halving
             //rewardValue = rewardValue / divider;
             rewardValue = (rewardValue / 100) * royalty * multiplier;

             if(balanceOf(parentAddr) > 0 || rewardsfor == RewardsFor.ALL){
                parent.totalReward += rewardValue;
                cycleReward += rewardValue;
                parentAddr.transfer(rewardValue);
                 emit PaidToDaddy(_msgSender(), parentAddr, rewardValue, i + 1);

             }

             executor = parent;
             multiplier += baseMultiplier;
             //divider = 2;
         }

         totalRoyalties += cycleReward;
    }



}