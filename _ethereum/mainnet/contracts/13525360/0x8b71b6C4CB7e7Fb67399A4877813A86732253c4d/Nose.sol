// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Util.sol";

function _getNose(uint256 seeds) pure returns (string memory) {
    uint256 hei = ((seeds % 33) * 80) / 33 + 80;
    uint256 wid = (((seeds / 33) % 33) * 50) / 33 + 50;
    uint256 x = 400;
    uint256[6] memory pt = [x, 450 - hei, x + wid, 450, x - wid, 450];
    string memory ret = "";
    for (uint256 i = 0; i < pt.length; i += 2) {
        ret = string(
            abi.encodePacked(
                ret,
                i == 0 ? "M" : "L",
                Util.toStr(pt[i]),
                ",",
                Util.toStr(pt[i + 1])
            )
        );
    }
    ret = string(abi.encodePacked(ret, "Z"));
    return ret;
}