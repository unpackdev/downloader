// SPDX-License-Identifier: UNLICENSED

/* *
 * Copyright 2021-2023 LI LI @ JINGTIAN & GONGCHENG.
 * All Rights Reserved.
 * */

pragma solidity ^0.8.8;

import "./IShareholdersAgreement.sol";
import "./SigPage.sol";

contract ShareholdersAgreement is IShareholdersAgreement, SigPage {
    using EnumerableSet for EnumerableSet.UintSet;    

    TermsRepo private _terms;
    RulesRepo private _rules;

    //####################
    //##    modifier    ##
    //####################

    modifier titleExist(uint256 title) {
        require(
            hasTitle(title),
            "SHA.mf.TE: title not exist"
        );
        _;
    }

    //##################
    //##  Write I/O   ##
    //##################

    function createTerm(uint title, uint version)
        external
        onlyGC
    {
        address gc = msg.sender;

        uint typeOfDoc = title > 3 ? 21 + title : 22 + title;

        bytes32 snOfDoc = bytes32((typeOfDoc << 224) + uint224(version << 192));

        DocsRepo.Doc memory doc = _rc.createDoc(snOfDoc, gc);        

        IAccessControl(doc.body).init(
            address(this),
            address(this),
            address(_rc),
            address(_gk)
        );

        IAccessControl(doc.body).setRoleAdmin(bytes32("Attorneys"), gc);

        _terms.terms[title] = doc.body;
        _terms.seqList.add(title);
    }

    function removeTerm(uint title) external onlyAttorney {
        if (_terms.seqList.remove(title)) {
            delete _terms.terms[title];
        }
    }

    // ==== Rules ====
    
    function addRule(bytes32 rule) external onlyAttorney {
        _addRule(rule);
    }

    function _addRule(bytes32 rule) private {
        uint seqOfRule = uint16(uint(rule) >> 240);

        _rules.rules[seqOfRule] = rule;
        _rules.seqList.add(seqOfRule);
    }


    function removeRule(uint256 seq) external onlyAttorney {
        if (_rules.seqList.remove(seq)) {
            delete _rules.rules[seq];
        }
    }

    function initDefaultRules() external onlyDK {

        bytes32[] memory rules = new bytes32[](15);        

        // DefualtGovernanceRule
        rules[0]  = bytes32(uint(0x000000000003e800000d0503e8003213880500241388000000000000140101f4));

        // DefaultVotingRules
        rules[1]  = bytes32(uint(0x00010c010100001a0b000001000f08070e010100000000000000000000000000));
        rules[2]  = bytes32(uint(0x00020c020100001388000100010f08070e010100000000000000000000000000));
        rules[3]  = bytes32(uint(0x00030c030100000000000101000008070e010100000000000000000000000000));
        rules[4]  = bytes32(uint(0x00040c040100001a0b000001000f08070e010100000000000000000000000000));
        rules[5]  = bytes32(uint(0x00050c050100001388000100010f08070e010100000000000000000000000000));
        rules[6]  = bytes32(uint(0x00060c060100001a0b000001000f08070e010100000000000000000000000000));
        rules[7]  = bytes32(uint(0x00070c070100001a0b000001000f08070e010100000000000000000000000000));
        rules[8]  = bytes32(uint(0x00080c080100001a0b000001000000001d010100000000000000000000000000));
        rules[9]  = bytes32(uint(0x00090c090100001388010000000000001d010100000000000000000000000000));
        rules[10] = bytes32(uint(0x000a0c0a0100001a0b010000000000001d010100000000000000000000000000));
        rules[11] = bytes32(uint(0x000b0c0b02138800000100000000000009010100000000000000000000000000));
        rules[12] = bytes32(uint(0x000c0c0c021a0b00000100000000000009010100000000000000000000000000));

        // DefaultFirstRefusalRules
        rules[13] = bytes32(uint(0x0200020101010100000000000000000000000000000000000000000000000000));
        rules[14] = bytes32(uint(0x0201020202010100000000000000000000000000000000000000000000000000));

        uint len = 15;
        while (len > 0) {
            _addRule(rules[len - 1]);
            len--;
        }

    }

    // ==== Finalize SHA ====

    function finalizeSHA() external {

        uint[] memory titles = getTitles();
        uint len = titles.length;

        while (len > 0) {
            IAccessControl(_terms.terms[titles[len-1]]).lockContents();
            len --;
        }

        lockContents();
    }
    

    //##################
    //##    读接口    ##
    //##################

    // ==== Terms ====

    function hasTitle(uint256 title) public view returns (bool) {
        return _terms.seqList.contains(title);
    }

    function qtyOfTerms() external view returns (uint256) {
        return _terms.seqList.length();
    }

    function getTitles() public view returns (uint256[] memory) {
        return _terms.seqList.values();
    }

    function getTerm(uint256 title) external view titleExist(title) returns (address) {
        return _terms.terms[title];
    }

    // ==== Rules ====
    
    function hasRule(uint256 seq) external view returns (bool) {
        return _rules.seqList.contains(seq);
    }

    function qtyOfRules() external view returns (uint256) {
        return _rules.seqList.length();
    }

    function getRules() external view returns (uint256[] memory) {
        return _rules.seqList.values();
    }

    function getRule(uint256 seq) external view returns (bytes32) {
        return _rules.rules[seq];
    }
}
