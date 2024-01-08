// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Util.sol";

function _getTTT(uint256 seed) pure returns (uint256[] memory) {
    uint256 idx = seed % 10;
    uint256[] memory tt;
    if (idx == 0) {
        tt = new uint256[](3);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 1;
        return tt;
    }
    if (idx == 1) {
        tt = new uint256[](3);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 1;
        return tt;
    }
    if (idx == 2) {
        tt = new uint256[](3);
        tt[0] = 1;
        tt[1] = 1;
        tt[2] = 0;
        return tt;
    }
    if (idx == 3) {
        tt = new uint256[](3);
        tt[0] = 1;
        tt[1] = 1;
        tt[2] = 1;
        return tt;
    }
    if (idx == 4) {
        tt = new uint256[](4);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 0;
        tt[3] = 1;
        return tt;
    }
    if (idx == 5) {
        tt = new uint256[](4);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 1;
        tt[3] = 0;
        return tt;
    }
    if (idx == 6) {
        tt = new uint256[](4);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 0;
        tt[3] = 1;
        return tt;
    }
    if (idx == 7) {
        tt = new uint256[](4);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 1;
        tt[3] = 0;
        return tt;
    }
    if (idx == 8) {
        tt = new uint256[](4);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 1;
        tt[3] = 1;
        return tt;
    }
    tt = new uint256[](4);
    tt[0] = 1;
    tt[1] = 1;
    tt[2] = 0;
    tt[3] = 1;
    return tt;
}

function _getBTT(uint256 seed) pure returns (uint256[] memory) {
    uint256 idx = seed % 10;
    uint256[] memory tt;
    if (idx == 0) {
        tt = new uint256[](3);
        tt[0] = 0;
        tt[1] = 0;
        tt[2] = 1;
        return tt;
    }
    if (idx == 1) {
        tt = new uint256[](3);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 0;
        return tt;
    }
    if (idx == 2) {
        tt = new uint256[](3);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 0;
        return tt;
    }
    if (idx == 3) {
        tt = new uint256[](3);
        tt[0] = 0;
        tt[1] = 0;
        tt[2] = 0;
        return tt;
    }
    if (idx == 4) {
        tt = new uint256[](4);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 0;
        tt[3] = 1;
        return tt;
    }
    if (idx == 5) {
        tt = new uint256[](4);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 0;
        tt[3] = 1;
        return tt;
    }
    if (idx == 6) {
        tt = new uint256[](4);
        tt[0] = 0;
        tt[1] = 1;
        tt[2] = 1;
        tt[3] = 0;
        return tt;
    }
    if (idx == 7) {
        tt = new uint256[](4);
        tt[0] = 1;
        tt[1] = 0;
        tt[2] = 1;
        tt[3] = 0;
        return tt;
    }
    if (idx == 8) {
        tt = new uint256[](4);
        tt[0] = 0;
        tt[1] = 0;
        tt[2] = 1;
        tt[3] = 0;
        return tt;
    }
    tt = new uint256[](4);
    tt[0] = 0;
    tt[1] = 1;
    tt[2] = 0;
    tt[3] = 0;
    return tt;
}

function _getMouth_Sub(uint256[] memory ofst) pure returns (string memory) {
    string memory str = "";
    for (uint256 i = 0; i < ofst.length; i += 2) {
        str = string(
            abi.encodePacked(
                str,
                "L",
                Util.toStr(ofst[i]),
                ",",
                Util.toStr(ofst[i + 1])
            )
        );
    }
    return str;
}

function _getMouth(uint256 seeds) pure returns (string memory, uint256) {
    string memory tt = _getMouthT(seeds);
    string memory bt = _getMouthB(seeds);
    return (
        string(
            abi.encodePacked(
                "M115,470L175,490",
                tt,
                "L625,490L665,470L625,670",
                bt,
                "L175,670Z"
            )
        ),
        seeds % 10
    );
}

function _getMouthT(uint256 seeds) pure returns (string memory) {
    uint256[] memory tbl = _getTTT(seeds);
    uint256 freq = tbl.length;
    uint256 pw = 450 / freq;
    uint256 pm = pw / 6;
    uint256 pm3 = pm * 5;
    uint256 st = 175;
    uint256 num = 0;
    for (uint256 i = 0; i < tbl.length; i++) num += tbl[i];
    uint256[] memory ofst = new uint256[](num * 10);
    uint256 tc = 0;
    for (uint256 i = 0; i < tbl.length; i++) {
        uint256 t = st;
        if (tbl[i] == 1) {
            uint256 idb = tc * 10;
            ofst[idb + 0] = t + pm;
            ofst[idb + 1] = 490;
            ofst[idb + 2] = t + pm;
            ofst[idb + 3] = 540;
            ofst[idb + 4] = t + pm3;
            ofst[idb + 5] = 540;
            ofst[idb + 6] = t + pm3;
            ofst[idb + 7] = 490;
            ofst[idb + 8] = t + pw;
            ofst[idb + 9] = 490;
            tc++;
        }
        st = t + pw;
    }
    string memory ut = _getMouth_Sub(ofst);
    return ut;
}

function _getMouthB(uint256 seeds) pure returns (string memory) {
    uint256[] memory tbl = _getBTT(seeds);
    uint256 freq = tbl.length;
    uint256 pw = 450 / freq;
    uint256 pm = pw / 6;
    uint256 pm3 = pm * 5;
    uint256 st = 625;
    uint256 num = 0;
    for (uint256 i = 0; i < tbl.length; i++) num += tbl[i];
    uint256[] memory ofst = new uint256[](num * 10);
    uint256 tc = 0;
    for (uint256 i = 0; i < tbl.length; i++) {
        uint256 t = st;
        if (tbl[i] == 1) {
            uint256 idb = tc * 10;
            ofst[idb + 0] = t - pm;
            ofst[idb + 1] = 670;
            ofst[idb + 2] = t - pm;
            ofst[idb + 3] = 620;
            ofst[idb + 4] = t - pm3;
            ofst[idb + 5] = 620;
            ofst[idb + 6] = t - pm3;
            ofst[idb + 7] = 670;
            ofst[idb + 8] = t - pw;
            ofst[idb + 9] = 670;
            tc++;
        }
        st = t - pw;
    }
    string memory bt = _getMouth_Sub(ofst);
    return bt;
}
