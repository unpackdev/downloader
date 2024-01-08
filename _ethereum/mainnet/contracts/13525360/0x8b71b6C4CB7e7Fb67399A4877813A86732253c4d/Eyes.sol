// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Util.sol";

function _getSPT(uint256 seed) pure returns (uint256[8] memory) {
    uint256 idx = seed % 6;
    if (idx == 0) return [uint256(0), 0, 1, 0, 0, 1, 0, 1];
    if (idx == 1) return [uint256(0), 1, 0, 0, 0, 1, 0, 1];
    if (idx == 2) return [uint256(1), 0, 1, 0, 0, 0, 1, 0];
    if (idx == 3) return [uint256(0), 1, 0, 1, 0, 0, 1, 0];
    if (idx == 4) return [uint256(1), 0, 0, 1, 0, 0, 1, 0];
    return [uint256(1), 0, 1, 0, 0, 1, 0, 0];
}

function _getPoint(
    bool clockwise,
    uint256 x,
    uint256 y,
    uint256 ofst
) pure returns (uint256[2] memory) {
    int256[8] memory tbl = [int256(1), 0, 0, 1, -1, 0, 0, -1];
    if (!clockwise) tbl = [int256(-1), 0, 0, 1, 1, 0, 0, -1];
    int256 mod = int256(ofst) % 250;
    uint256 div = ofst / 250;
    int256[2] memory p = [int256(x), int256(y)];
    uint256 i = 0;
    for (; i < div; i++) {
        p[0] += 250 * tbl[i * 2];
        p[1] += 250 * tbl[i * 2 + 1];
    }
    p[0] += mod * tbl[i * 2];
    p[1] += mod * tbl[i * 2 + 1];
    return [uint256(p[0]), uint256(p[1])];
}

function _getOffset(
    uint256[8] memory ptn,
    uint256 seeds,
    string memory salt
) pure returns (uint256[3] memory) {
    uint256 seed = uint256(keccak256(abi.encodePacked(salt, seeds)));
    uint256[3] memory rnd;
    seed /= 100;
    rnd[0] = seed % 100;
    seed /= 100;
    rnd[1] = seed % 100;
    seed /= 100;
    rnd[2] = seed % 100;
    uint256[3] memory ret;
    uint256 width = 125;
    uint256 idx = 0;
    for (uint256 i = 0; i < ptn.length; i++) {
        if (ptn[i] == 1) {
            ret[idx] = i * width + (rnd[idx] * 64) / 100 + 32;
            idx++;
        }
    }
    return ret;
}

function _reducer(uint256[] memory points) pure returns (string memory) {
    string memory ret = "";
    for (uint256 i = 0; i < points.length; i += 2) {
        ret = string(
            abi.encodePacked(
                ret,
                i == 0 ? "M" : "L",
                Util.toStr(points[i]),
                ",",
                Util.toStr(points[i + 1])
            )
        );
    }
    return string(abi.encodePacked(ret, "Z"));
}

function _getEyes(uint256 seeds) pure returns (string[2] memory, uint256) {
    uint256[8] memory ptn = _getSPT(seeds);
    uint256[3] memory ofs = _getOffset(ptn, seeds, "lefteye");
    uint256[] memory lep = new uint256[](6);
    for (uint256 i = 0; i < ofs.length; i++) {
        uint256[2] memory pt = _getPoint(true, 100, 180, ofs[i]);
        lep[i * 2] = pt[0];
        lep[i * 2 + 1] = pt[1];
    }
    ofs = _getOffset(ptn, seeds, "righteye");
    uint256[] memory rep = new uint256[](6);
    for (uint256 i = 0; i < ofs.length; i++) {
        uint256[2] memory pt = _getPoint(false, 700, 180, ofs[i]);
        rep[i * 2] = pt[0];
        rep[i * 2 + 1] = pt[1];
    }
    return ([_reducer(lep), _reducer(rep)], seeds % 5);
}
