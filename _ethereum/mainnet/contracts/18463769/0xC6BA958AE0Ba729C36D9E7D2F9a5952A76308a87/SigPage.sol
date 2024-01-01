// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./ISigPage.sol";

import "./AccessControl.sol";

contract SigPage is ISigPage, AccessControl {
    using ArrayUtils for uint256[];
    using EnumerableSet for EnumerableSet.UintSet;
    using SigsRepo for SigsRepo.Page;

    SigsRepo.Page[2] internal _sigPages;

    //####################
    //##    设置接口     ##
    //####################

    function circulateDoc() external onlyKeeper {
        _sigPages[0].circulateDoc();
        _sigPages[1].circulateDoc();
        emit CirculateDoc();
    }

    function setTiming(bool initPage, uint signingDays, uint closingDays) 
        external attorneyOrKeeper
    {
        initPage ? _sigPages[0].setTiming(signingDays, closingDays) :
            _sigPages[1].setTiming(signingDays, closingDays);
    }

    function addBlank(bool initPage, bool beBuyer, uint256 seqOfDeal, uint256 acct)
        external attorneyOrKeeper
    {
        initPage ? _sigPages[0].addBlank(beBuyer, seqOfDeal, acct) :
            _sigPages[1].addBlank(beBuyer, seqOfDeal, acct);
    }

    function removeBlank(bool initPage, uint256 seqOfDeal, uint256 acct)
        external attorneyOrKeeper
    {
        initPage ? _sigPages[0].removeBlank(seqOfDeal, acct) :
            _sigPages[1].removeBlank(seqOfDeal, acct);
    }

    function signDoc(bool initPage, uint256 caller, bytes32 sigHash)
        external onlyKeeper
    {
        if (initPage) {
            _sigPages[0].signDoc(caller, sigHash);
        } else {
            _sigPages[1].signDoc(caller, sigHash);
        }
    }

    function regSig(uint256 signer, uint sigDate, bytes32 sigHash)
        external onlyKeeper returns (bool flag)
    {
        flag = _sigPages[1].regSig(signer, sigDate, sigHash);
    }

    //##################
    //##   read I/O   ##
    //##################

    function getParasOfPage(bool initPage) external view
        returns (SigsRepo.Signature memory) 
    {
        return initPage ? _sigPages[0].blanks[0].sig :
            _sigPages[1].blanks[0].sig;
    }

    function circulated() external view returns(bool) {
        return _sigPages[0].circulated();
    }
        
    function established() external view
        returns (bool flag) 
    {
        flag =  _sigPages[1].buyers.length() > 0 
                ? _sigPages[1].established() && _sigPages[0].established() 
                : _sigPages[0].established();
    }

    function getCirculateDate() external view returns(uint48) {
        return _sigPages[0].getCirculateDate();
    }

    function getSigningDays() external view returns(uint16) {
        return _sigPages[0].getSigningDays();
    }

    function getClosingDays() external view returns(uint16) {
        return _sigPages[0].getClosingDays();
    }

    function getSigDeadline() external view returns(uint48) {
        return _sigPages[0].getSigDeadline();
    }

    function getClosingDeadline() external view returns(uint48) {
        return _sigPages[0].getClosingDeadline();
    }

    function isBuyer(bool initPage, uint256 acct)
        public view returns(bool flag)
    {
        flag = initPage ? _sigPages[0].buyers.contains(acct) :
            _sigPages[1].buyers.contains(acct);
    }

    function isSeller(bool initPage, uint256 acct)
        public view returns(bool flag)
    {
        flag = initPage ? _sigPages[0].sellers.contains(acct) :
            _sigPages[1].sellers.contains(acct);
    }

    function isParty(uint256 acct) external view returns (bool flag) {
        flag = _sigPages[0].buyers.contains(acct) ||
            _sigPages[0].sellers.contains(acct) ||
            _sigPages[1].buyers.contains(acct) ||
            _sigPages[1].sellers.contains(acct);
    }

    function isInitSigner(uint256 acct)
        external view returns (bool flag) 
    {
        flag = _sigPages[0].isSigner(acct);
    }


    function isSigner(uint256 acct)
        external view returns (bool flag) 
    {
        flag = _sigPages[0].isSigner(acct) ||
            _sigPages[1].isSigner(acct);
    }

    function getBuyers(bool initPage)
        public view returns (uint256[] memory buyers)
    {
        buyers = initPage 
            ? _sigPages[0].buyers.values() 
            : _sigPages[1].buyers.values();
    }

    function getSellers(bool initPage)
        public view returns (uint256[] memory sellers)
    {
        sellers = initPage 
            ? _sigPages[0].sellers.values()
            : _sigPages[1].sellers.values();
    }

    function getParties() external view
        returns (uint256[] memory parties)
    {
        uint256[] memory buyers = 
            getBuyers(true).merge(getBuyers(false));

        uint256[] memory sellers = 
            getSellers(true).merge(getSellers(false));
        
        parties = buyers.merge(sellers);
    }

    function getSigOfParty(bool initPage, uint256 acct) 
        external view
        returns (
            uint256[] memory seqOfDeals, 
            SigsRepo.Signature memory sig,
            bytes32 sigHash
    ) {
        if (initPage) {
            return _sigPages[0].sigOfParty(acct);
        } else {
            return _sigPages[1].sigOfParty(acct);
        }
    }
    
    function getSigsOfPage(bool initPage) 
        external view
        returns (
            SigsRepo.Signature[] memory sigsOfBuyer, 
            SigsRepo.Signature[] memory sigsOfSeller
        ) 
    {
        if (initPage) {
            return _sigPages[0].sigsOfPage();
        } else {
            return _sigPages[1].sigsOfPage();
        }
    }
}
