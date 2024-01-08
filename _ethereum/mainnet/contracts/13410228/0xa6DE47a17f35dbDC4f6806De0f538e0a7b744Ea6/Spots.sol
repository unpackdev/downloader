// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Util.sol";

library SpotsUtil {
    bytes private constant char_table = "_ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    function _strToIndex(string memory abc)
        internal
        pure
        returns (uint256[] memory)
    {
        bytes memory str = bytes(abc);
        uint256[] memory res = new uint256[](str.length);
        for (uint256 j = 0; j < str.length; j++) {
            for (uint256 i = 0; i < char_table.length; i++) {
                if (str[j] == char_table[i]) res[j] = i;
            }
        }
        return res;
    }

    function _getSpots(uint256 spotstype)
        internal
        pure
        returns (string memory)
    {
        string[16] memory pattern_tbl = [
            "CHANGETHEWORLD",
            "ITSNOWORNEVER",
            "TRYSOMETHINGNEW",
            "NEVERLOOKBACK",
            "MAKEITHAPPEN",
            "NOTHINGCANSTOPU",
            "BETHECHANGE",
            "DONTTHINKFEEL",
            "YOUCANMAKEIT",
            "KEEPYOURHEADUP",
            "DEEDSNOTWORDS",
            "DONTBEAFRAID",
            "SHOOTTHEMOON",
            "TAKEACHANCE",
            "IMNOTSCARED",
            "JUSTKEEPGOING"
        ];

        uint256[] memory str = _strToIndex(
            pattern_tbl[spotstype % pattern_tbl.length]
        );
        string memory ret = "";

        for (uint256 i = 0; i < str.length && i < 16; i++) {
            uint256[] memory cursor = _spotTable(i);
            uint256 num = str[i];
            uint256[3] memory ternary = [
                (num / 9) % 3,
                (num / 3) % 3,
                (num / 1) % 3
            ];
            ret = string(
                abi.encodePacked(
                    ret,
                    _getCircle(cursor[0], cursor[1], ternary[0] * 3),
                    _getCircle(cursor[2], cursor[3], ternary[1] * 3),
                    _getCircle(cursor[4], cursor[5], ternary[2] * 2)
                )
            );
        }

        ret = string(abi.encodePacked('<g fill="#543">', ret, "</g>"));

        return ret;
    }

    function _getCircle(
        uint256 x,
        uint256 y,
        uint256 r
    ) private pure returns (string memory) {
        return
            r > 0
                ? string(
                    abi.encodePacked(
                        '<circle cx="',
                        Util.toStr(x),
                        '" cy="',
                        Util.toStr(y),
                        '" r="',
                        Util.toStr(r),
                        '" />'
                    )
                )
                : "";
    }

    function _spotTable(uint256 num) internal pure returns (uint256[] memory) {
        uint256[96] memory spot_table = [
            uint256(160),
            230,
            169,
            274,
            181,
            315,
            196,
            354,
            214,
            391,
            236,
            425,
            260,
            456,
            287,
            486,
            318,
            513,
            351,
            537,
            387,
            559,
            427,
            578,
            469,
            596,
            515,
            610,
            564,
            623,
            615,
            633,
            180,
            220,
            194,
            263,
            210,
            304,
            228,
            343,
            249,
            379,
            273,
            413,
            299,
            444,
            327,
            473,
            358,
            500,
            391,
            524,
            426,
            547,
            464,
            566,
            504,
            584,
            547,
            599,
            592,
            612,
            640,
            622,
            200,
            210,
            217,
            253,
            236,
            293,
            258,
            331,
            281,
            367,
            306,
            400,
            333,
            432,
            362,
            461,
            393,
            488,
            425,
            512,
            460,
            534,
            497,
            554,
            536,
            572,
            576,
            587,
            619,
            600,
            663,
            611
        ];
        uint256[] memory ret = new uint256[](6);
        uint256 index = num * 2;
        ret[0] = spot_table[index];
        ret[1] = spot_table[index + 1];
        ret[2] = spot_table[index + 32];
        ret[3] = spot_table[index + 33];
        ret[4] = spot_table[index + 64];
        ret[5] = spot_table[index + 65];
        return ret;
    }
}
