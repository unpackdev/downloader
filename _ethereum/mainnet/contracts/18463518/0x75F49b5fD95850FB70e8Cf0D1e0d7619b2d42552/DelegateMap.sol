// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IRegisterOfMembers.sol";
import "./IRegisterOfDirectors.sol";

library DelegateMap {

    struct LeavesInfo {
        uint64 weight;
        uint32 emptyHead;
    }

    struct Voter {
        uint40 delegate;
        uint64 weight;
        uint64 repWeight;
        uint32 repHead;
        uint[] principals;
    }

    struct Map {
        mapping(uint256 => Voter) voters;
    }

    // #################
    // ##    Write    ##
    // #################

    function entrustDelegate(
        Map storage map,
        uint principal,
        uint delegate,
        uint weight
    ) public returns (bool flag) {
        require(principal != 0, "DM.ED: zero principal");
        require(delegate != 0, "DM.ED: zero delegate");
        require(principal != delegate,"DM.ED: self delegate");

        if (map.voters[principal].delegate == 0 && 
            map.voters[delegate].delegate == 0) 
        {
            Voter storage p = map.voters[principal];
            Voter storage d = map.voters[delegate];

            p.delegate = uint40(delegate);
            p.weight = uint64(weight);

            d.repHead += (p.repHead + 1);
            d.repWeight += (p.repWeight + p.weight);

            d.principals.push(uint40(principal));
            _consolidatePrincipals(p.principals, d);

            flag = true;
        }
    }

    function _consolidatePrincipals(uint[] memory principals, Voter storage d) private {
        uint len = principals.length;

        while (len > 0) {
            d.principals.push(principals[len-1]);
            len--;
        }        
    }

    // #################
    // ##    Read     ##
    // #################

    function getDelegateOf(Map storage map, uint acct)
        public
        view
        returns (uint d)
    {
        while (acct > 0) {
            d = acct;
            acct = map.voters[d].delegate;
        }
    }

    function updateLeavesWeightAtDate(Map storage map, uint256 acct, uint baseDate, IRegisterOfMembers _rom)
        public
    {
        LeavesInfo memory info;
        Voter storage voter = map.voters[acct];

        uint[] memory leaves = voter.principals;
        uint256 len = leaves.length;

        while (len > 0) {
            uint64 w = _rom.votesAtDate(acct, baseDate);
            if (w > 0) {
                info.weight += w;
            } else {
                info.emptyHead++;
            }
            len--;
        }
        
        voter.weight = _rom.votesAtDate(acct, baseDate);
        voter.repWeight = info.weight;
        voter.repHead = uint32(leaves.length) - info.emptyHead;
    }

    function updateLeavesHeadcountOfDirectors(Map storage map, uint256 acct, IRegisterOfDirectors _rod) 
        public 
    {
        uint[] memory leaves = map.voters[acct].principals;
        uint256 len = leaves.length;

        uint32 repHead;        
        while (len > 0) {
            if (_rod.isDirector(acct)) repHead++;
            len--;
        }

        map.voters[acct].repHead = repHead;
    }
}
