// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";
import "./IRegisterOfShares.sol";

import "./DealsRepo.sol";
import "./RulesParser.sol";
import "./SharesRepo.sol";

library LinksRepo {
    using EnumerableSet for EnumerableSet.UintSet;
    using RulesParser for bytes32;

    enum TriggerTypeOfAlongs {
        NoConditions,
        ControlChanged,
        ControlChangedWithHigherPrice,
        ControlChangedWithHigherROE
    }

    struct Link {
        RulesParser.LinkRule linkRule;
        EnumerableSet.UintSet followersList;
    }

    struct Repo {
        // dragger => Link
        mapping(uint256 => Link) links;
        EnumerableSet.UintSet  draggersList;
    }

    modifier draggerExist(Repo storage repo, uint dragger, IRegisterOfMembers _rom) {
        require(isDragger(repo, dragger, _rom), "LR.mf.draggerExist: not");
        _;
    }

    // ###############
    // ## Write I/O ##
    // ###############

    function addDragger(Repo storage repo, bytes32 rule, uint256 dragger, IRegisterOfMembers _rom) public {
        uint40 groupRep = _rom.groupRep(dragger);
        if (repo.draggersList.add(groupRep))
            repo.links[groupRep].linkRule = rule.linkRuleParser();
    }

    function removeDragger(Repo storage repo, uint256 dragger) public {
        if (repo.draggersList.remove(dragger))
            delete repo.links[dragger];
    }

    function addFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.add(uint40(follower));
    }

    function removeFollower(Repo storage repo, uint256 dragger, uint256 follower) public {
        repo.links[dragger].followersList.remove(follower);
    }

    // ################
    // ##  查询接口  ##
    // ################

    function isDragger(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.draggersList.contains(groupRep);
    }

    function getLinkRule(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom)
        returns (RulesParser.LinkRule memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].linkRule;
    }

    function isFollower(
        Repo storage repo, 
        uint256 dragger, 
        uint256 follower,
        IRegisterOfMembers _rom
    ) public view draggerExist(repo, dragger, _rom) 
        returns (bool) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.contains(uint40(follower));
    }

    function getDraggers(Repo storage repo) public view returns (uint256[] memory) {
        return repo.draggersList.values();
    }

    function getFollowers(Repo storage repo, uint256 dragger, IRegisterOfMembers _rom) 
        public view draggerExist(repo, dragger, _rom) returns (uint256[] memory) 
    {
        uint40 groupRep = _rom.groupRep(dragger);
        return repo.links[groupRep].followersList.values();
    }

    function priceCheck(
        Repo storage repo,
        DealsRepo.Deal memory deal,
        IRegisterOfShares _ros,
        IRegisterOfMembers _rom
    ) public view returns (bool) {

        RulesParser.LinkRule memory lr = 
            getLinkRule(repo, deal.head.seller, _rom);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherPrice)) 
            return (deal.head.priceOfPaid >= lr.rate);

        SharesRepo.Share memory share = 
            _ros.getShare(deal.head.seqOfShare);

        if (lr.triggerType == uint8(TriggerTypeOfAlongs.ControlChangedWithHigherROE))
            return (_roeOfDeal(
                deal.head.priceOfPaid, 
                share.head.priceOfPaid, 
                deal.head.closingDeadline, 
                share.head.issueDate) >= lr.rate);

        return true;
    }

    function _roeOfDeal(
        uint32 dealPrice,
        uint32 issuePrice,
        uint48 closingDeadline,
        uint48 issueDateOfShare
    ) private pure returns (uint32 roe) {
        require(dealPrice > issuePrice, "ROE: NEGATIVE selling price");
        require(closingDeadline > issueDateOfShare, "ROE: NEGATIVE holding period");

        uint deltaPrice = uint(dealPrice - issuePrice);
        uint deltaDate = uint(closingDeadline - issueDateOfShare);

        roe = uint32(deltaPrice * 10000 / uint(issuePrice) * 31536000 / deltaDate);
    }
}
