// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./EnumerableSet.sol";

library SigsRepo {
    using EnumerableSet for EnumerableSet.UintSet;

    struct Signature {
        uint40 signer;
        uint48 sigDate;
        uint64 blocknumber;
        bool flag;
        uint16 para;
        uint16 arg;
        uint16 seq;
        uint16 attr;
        uint32 data;
    }

    struct Blank{
        EnumerableSet.UintSet seqOfDeals;
        Signature sig;
        bytes32 sigHash;
    }

    // blanks[0].sig {
    //     sigDate: circulateDate;
    //     flag: established;
    //     para: counterOfBlanks;
    //     arg: counterOfSigs;
    //     seq: signingDays;
    //     attr: closingDays;
    // }

    struct Page {
        // party => Blank
        mapping(uint256 => Blank) blanks;
        EnumerableSet.UintSet buyers;
        EnumerableSet.UintSet sellers;
    }

    //###################
    //##    设置接口    ##
    //###################

    function circulateDoc(
        Page storage p
    ) public {
        p.blanks[0].sig.sigDate = uint48(block.timestamp);
    }

    function setTiming(
        Page storage p,
        uint signingDays,
        uint closingDays
    ) public {
        // require(!circulated(p), "SR.SD: doc already circulated");
        p.blanks[0].sig.seq = uint16(signingDays);
        p.blanks[0].sig.attr = uint16(closingDays);
    }

    function addBlank(
        Page storage p,
        bool beBuyer,
        uint256 seq,
        uint256 acct
    ) public {
        require (seq > 0, "SR.AB: zero seq");
        require (acct > 0, "SR.AB: zero acct");

        
        if (beBuyer) {
            require(!p.sellers.contains(acct), "SR.AB: seller intends to buy");
            p.buyers.add(acct);
        } else {
            require(!p.buyers.contains(acct), "SR.AB: buyer intends to sell");
            p.sellers.add(acct);
        }

        if (p.blanks[uint40(acct)].seqOfDeals.add(uint16(seq)))
            _increaseCounterOfBlanks(p);
    }

    function removeBlank(
        Page storage p,
        uint256 seq,
        uint256 acct
    ) public {
        if (p.buyers.contains(acct) || p.sellers.contains(acct)) {
            if (p.blanks[acct].seqOfDeals.remove(seq))
                _decreaseCounterOfBlanks(p);

            if (p.blanks[acct].seqOfDeals.length() == 0) {
                delete p.blanks[acct]; 
                p.buyers.remove(acct) || p.sellers.remove(acct);
            }
        }
    }

    function signDoc(Page storage p, uint256 acct, bytes32 sigHash) 
        public 
    {
        require(block.timestamp < getSigDeadline(p) ||
            getSigningDays(p) == 0,
            "SR.SD: missed sigDeadline");

        require(!established(p),
            "SR.SD: Doc already established");

        if ((p.buyers.contains(acct) || p.sellers.contains(acct)) &&
            p.blanks[acct].sig.sigDate == 0) {

            Signature storage sig = p.blanks[acct].sig;

            sig.signer = uint40(acct);
            sig.sigDate = uint48(block.timestamp);
            sig.blocknumber = uint64(block.number);

            p.blanks[acct].sigHash = sigHash;

            _increaseCounterOfSigs(p, p.blanks[acct].seqOfDeals.length());
        }
    }

    function regSig(Page storage p, uint256 acct, uint sigDate, bytes32 sigHash)
        public returns (bool flag)
    {
        require(block.timestamp < getSigDeadline(p),
            "SR.RS: missed sigDeadline");

        require(!established(p),
            "SR.regSig: Doc already established");

        if (p.buyers.contains(acct) || p.sellers.contains(acct)) {

            Signature storage sig = p.blanks[acct].sig;

            sig.signer = uint40(acct);
            sig.sigDate = uint48(sigDate);
            sig.blocknumber = uint64(block.number);

            p.blanks[acct].sigHash = sigHash;

            _increaseCounterOfSigs(p, 1);

            flag = true;
        }

    }

    function _increaseCounterOfBlanks(Page storage p) private {
        p.blanks[0].sig.para++;
    }

    function _decreaseCounterOfBlanks(Page storage p) private {
        p.blanks[0].sig.para--;
    }

    function _increaseCounterOfSigs(Page storage p, uint qtyOfDeals) private {
        p.blanks[0].sig.arg += uint16(qtyOfDeals);
    }

    //####################
    //##    查询接口     ##
    //####################

    function circulated(Page storage p) public view returns (bool)
    {
        return p.blanks[0].sig.sigDate > 0;
    }

    function established(Page storage p) public view returns (bool)
    {
        // return p.blanks[0].sig.flag;
        return counterOfBlanks(p) > 0 
            && counterOfBlanks(p) == counterOfSigs(p);
    }

    function counterOfBlanks(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.para;
    }

    function counterOfSigs(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.arg;
    }

    function getCirculateDate(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate;
    }

    function getSigningDays(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.seq;
    }

    function getClosingDays(Page storage p) public view returns(uint16) {
        return p.blanks[0].sig.attr;
    }

    function getSigDeadline(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate + uint48(p.blanks[0].sig.seq) * 86400; 
    }

    function getClosingDeadline(Page storage p) public view returns(uint48) {
        return p.blanks[0].sig.sigDate + uint48(p.blanks[0].sig.attr) * 86400; 
    }

    function isSigner(Page storage p, uint256 acct) 
        public view returns (bool) 
    {
        return p.blanks[acct].sig.signer > 0;
    }

    function sigOfParty(Page storage p, uint256 acct) public view
        returns (
            uint256[] memory seqOfDeals, 
            Signature memory sig,
            bytes32 sigHash
        ) 
    {
        seqOfDeals = p.blanks[acct].seqOfDeals.values();
        sig = p.blanks[acct].sig;
        sigHash = p.blanks[acct].sigHash;
    }

    function sigsOfPage(Page storage p) public view
        returns (
            Signature[] memory sigsOfBuyer, 
            Signature[]memory sigsOfSeller
        )
    {
        sigsOfBuyer = sigsOfSide(p, p.buyers);
        sigsOfSeller = sigsOfSide(p, p.sellers);
    }

    function sigsOfSide(Page storage p, EnumerableSet.UintSet storage partiesOfSide) 
        public view
        returns (Signature[] memory)
    {
        uint256[] memory parties = partiesOfSide.values();
        uint256 len = parties.length;

        Signature[] memory sigs = new Signature[](len);

        while (len > 0) {
            sigs[len-1] = p.blanks[parties[len-1]].sig;
            len--;
        }

        return sigs;
    }


}
