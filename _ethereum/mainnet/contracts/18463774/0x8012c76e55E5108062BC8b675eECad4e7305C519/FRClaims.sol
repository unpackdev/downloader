// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;


import "./IRegisterOfMembers.sol";

library FRClaims {

    struct Claim {
        uint16 seqOfDeal;
        uint40 claimer;
        uint64 weight;
        uint64 ratio;
        uint48 sigDate;
        bytes32 sigHash;
    }

    struct Package {
        uint64 sumOfWeight;
        Claim[] claims;
        mapping(uint256 => bool) isClaimer;
    }

    // packages[0] {
    //     claims: deals;
    //     isClaimer: isClaimer;
    // }

    struct Claims {
        // seqOfDeal => Package
        mapping(uint256 => Package) packages;
    }

    //##################
    //##  Write I/O  ##
    //##################

    function claimFirstRefusal(
        Claims storage cls,
        uint256 seqOfDeal,
        uint256 acct,
        bytes32 sigHash
    ) public {

        Claim memory cl = Claim({
            seqOfDeal: uint16(seqOfDeal),
            claimer: uint40(acct),
            weight: 0,
            ratio: 0,
            sigDate: uint48(block.timestamp),
            sigHash: sigHash
        });

        require(cl.seqOfDeal > 0, "FRClaims.exec: zero seqOfDeal");

        require(!isClaimerOfDeal(cls, cl.seqOfDeal, cl.claimer),
            "FRClaims.exec: double claim");

        if (!isDeal(cls, cl.seqOfDeal))
            cls.packages[0].claims.push(cl);
        
        Package storage p = cls.packages[cl.seqOfDeal];

        p.isClaimer[cl.claimer] = true;
        p.claims.push(cl);

        cls.packages[0].isClaimer[cl.claimer] = true;
    }

    function computeFirstRefusal(
        Claims storage cls,
        uint256 seqOfDeal,
        IRegisterOfMembers rom
    ) public returns (Claim[] memory output) {

        require(isDeal(cls, seqOfDeal), "FRClaims.accept: no claims received");

        Package storage p = cls.packages[seqOfDeal];

        if (p.sumOfWeight == 0) {
            uint256 len = p.claims.length;            
            uint256 i;

            while (i < len) {
                Claim storage cl = p.claims[i];

                uint64 weight = rom.votesInHand(cl.claimer);
                cl.weight = weight;
                p.sumOfWeight += weight;
                i++;
            }

            i = 0;
            while(i < len) {
                Claim storage cl = p.claims[i];

                cl.ratio = cl.weight * 10000 / p.sumOfWeight;
                i++; 
            }
        } else revert("FRClaims: already created");

        output = p.claims;
    }

    //  ################################
    //  ##       查询接口              ##
    //  ################################

    function isClaimer(Claims storage cls, uint acct) public view returns(bool) {
        return cls.packages[0].isClaimer[acct];
    }

    function isClaimerOfDeal(
        Claims storage cls, 
        uint seqOfDeal, 
        uint acct
    ) public view returns(bool) {
        return cls.packages[seqOfDeal].isClaimer[acct];
    }

    function isDeal(
        Claims storage cls,
        uint seqOfDeal
    ) public view returns(bool) {
        return cls.packages[seqOfDeal].claims.length > 0;
    }

    function getDeals(Claims storage cls) public view returns(uint[] memory) {
        Claim[] memory claims = cls.packages[0].claims;
        uint len = claims.length;
        uint[] memory deals = new uint[](len);

        while (len > 0) {
            deals[len - 1] = claims[len - 1].seqOfDeal;
            len--;
        }

        return deals;
    }

    function getClaimsOfDeal(Claims storage cls, uint256 seqOfDeal)
        public view returns (Claim[] memory)
    {
        require(isDeal(cls, seqOfDeal), "FRD.COFR: not a targetDeal");
        return cls.packages[seqOfDeal].claims;
    }

    function allAccepted(Claims storage cls) public view returns (bool) {

        uint[] memory deals = getDeals(cls);
        uint len = deals.length;

        while (len > 0) {
            if (cls.packages[deals[len - 1]].sumOfWeight == 0)
                return false;
            len--;
        }

        return true;
    }

}
