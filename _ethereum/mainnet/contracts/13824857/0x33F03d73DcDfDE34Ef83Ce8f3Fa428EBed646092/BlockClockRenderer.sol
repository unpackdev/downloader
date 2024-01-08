// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// S U N M O N T U E W E D T H U F R I S A T
// J A N F E B M A R A P R M A Y J U N J U L
// A U G S E P O C T N O V D E C 0 0 1 0 0 2
// 0 0 3 0 0 4 0 0 5 0 0 6 0 0 7 0 0 8 0 0 9
// 0 1 0 0 1 1 0 1 2 0 1 3 0 1 4 0 1 5 0 1 6
// 0 1 7 0 1 8 0 1 9 0 2 0 0 2 1 0 2 2 0 2 3
// 0 2 | --------- | 0 2 7 0 2 8 0 2 9 0 3 0
// 0 3 | B L O C K | 0 0 2 0 0 3 0 0 4 0 0 5
// 0 0 | ----------------- | 1 0 0 1 1 0 0 0
// 0 0 1 0 0 2 | C L O C K | 0 5 0 0 6 0 0 7
// 0 0 8 0 0 9 ----------- | 1 2 0 1 3 0 1 4
// 0 1 5 0 1 6 0 1 7 0 1 8 0 1 9 0 2 0 0 2 1
// | --- | 2 3 0 2 4 0 2 5 0 2 6 0 2 7 0 2 8
// | B Y   --------------------- | 3 4 0 3 5
// | --- | @ S A M M Y B A U C H | 4 1 0 4 2
// 0 4 3 ----------------------- | 4 8 0 4 9
// 0 5 0 0 5 1 0 5 2 0 5 3 0 5 4 0 5 5 0 5 6
// 0 5 7 0 5 8 0 5 9 0 0 0 0 0 1 0 0 2 0 0 3
// 0 0 4 0 0 5 0 0 6 0 0 7 0 0 8 0 0 9 0 1 0
// 0 1 1 0 1 2 0 1 3 0 1 4 0 1 5 0 1 6 0 1 7
// 0 1 8 0 1 9 0 2 0 0 2 1 0 2 2 0 2 3 0 2 4
// 0 2 5 0 2 6 0 2 7 0 2 8 0 2 9 0 3 0 0 3 1
// 0 3 2 0 3 3 0 3 4 0 3 5 0 3 6 0 3 7 0 3 8
// 0 3 9 0 4 0 0 4 1 0 4 2 0 4 3 0 4 4 0 4 5
// 0 4 6 0 4 7 0 4 8 0 4 9 0 5 0 0 5 1 0 5 2
// 0 5 3 0 5 4 0 5 5 0 5 6 0 5 7 0 5 8 0 5 9

import "./Ownable.sol";

import "./Base64.sol";
import "./DateTime.sol";
import "./DynamicBuffer.sol";
import "./EssentialStrings.sol";

interface ICorruptionsFont {
    function font() external view returns (string memory);
}

contract BlockClockRenderer is Ownable {
    using DynamicBuffer for bytes;
    using EssentialStrings for uint256;
    using EssentialStrings for uint24;
    using EssentialStrings for uint8;

    ICorruptionsFont private font;

    constructor() {}

    function setFont(address fontAddress) external onlyOwner {
        font = ICorruptionsFont(fontAddress);
    }

    /* solhint-disable quotes */

    function svgBase64Data(
        int8 hourOffset,
        uint24 hexCode,
        uint256 timestamp
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(svgRaw(hourOffset, hexCode, timestamp)))
            );
    }

    function svgRaw(
        int8 hourOffset,
        uint24 hexCode,
        uint256 timestamp
    ) public view returns (bytes memory) {
        uint256 _timestamp = timestamp == 0
            ? uint256(int256(block.timestamp) + int256(hourOffset) * 1 hours)
            : timestamp;

        bytes memory svg = DynamicBuffer.allocate(2**16); // 64KB - reduce?

        (, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = BokkyPooBahsDateTimeLibrary
            .timestampToDateTime(_timestamp);

        bytes memory elementClasses = abi.encodePacked(
            dotwClass(_timestamp),
            monthClass(month),
            dayClass(day),
            hourClass(hour),
            minuteClass(minute),
            secondClass(second)
        );

        svg.appendSafe(
            abi.encodePacked(
                "<svg viewBox='0 0 1024 1024' width='1024' height='1024' xmlns='http://www.w3.org/2000/svg'>",
                '<style> @font-face { font-family: CorruptionsFont; src: url("',
                font.font(),
                '") format("opentype"); } ',
                ".wk { letter-spacing: 24px; } .base{fill:#504f54;font-family:CorruptionsFont;font-size: 36px;} ",
                elementClasses,
                "{fill: ",
                hexCode.toHtmlHexString(),
                ";} </style> ",
                '<rect width="100%" height="100%" fill="#181A18" /> '
            )
        );

        for (uint256 i = 1; i < 27; i++) {
            svg.appendSafe(renderRow(i));
        }

        svg.appendSafe(" </svg>");

        return svg;
    }

    function renderRow(uint256 rowNum) internal view returns (bytes memory) {
        bytes memory row = DynamicBuffer.allocate(2**16); // 64KB
        row.appendSafe(abi.encodePacked('<text x="0" y="', ((rowNum + 1) * 36).toString(), '" class="base"> '));
        string[7] memory rowLabels = rowElements(rowNum - 1);

        for (uint256 i = 0; i < 7; i++) {
            row.appendSafe(
                abi.encodePacked(
                    '<tspan class="',
                    abi.encodePacked("wk el", rowNum.toString(), i.toString()),
                    '"  x="',
                    (46 + (138 * i)).toString(),
                    '">',
                    rowLabels[i],
                    "</tspan> "
                )
            );
        }

        row.appendSafe("</text> ");

        return row;
    }

    function rowElements(uint256 rowIndex) internal view returns (string[7] memory row) {
        if (rowIndex > 2) {
            return paddedNumberRow(rowIndex);
        }

        if (rowIndex == 0) return ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        if (rowIndex == 1) return ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL"];
        if (rowIndex == 2) return ["AUG", "SEP", "OCT", "NOV", "DEC", "001", "002"];
    }

    function paddedNumberRow(uint256 rowIndex) internal view returns (string[7] memory row) {
        int256 maxUnit = 59;

        for (int256 index = 0; index < 7; index++) {
            int256 start = int256(rowIndex < 9 ? (rowIndex * 7) - 18 : (rowIndex - 8) * 7 - 6);

            if (rowIndex == 7) {
                maxUnit = 31;

                if (index == 1) {
                    row[uint256(index)] = "012";
                    continue;
                }

                if (index > 1) {
                    start = -1;
                }
            }

            if (rowIndex == 8) {
                maxUnit = 11;
                start = 6;
            }

            int256 unit = start + index;

            if (unit > maxUnit) {
                unit = unit - maxUnit - 1;
            }

            row[uint256(index)] = uint256(unit).toPaddedNumberString();
        }
    }

    function dotwClass(uint256 timestamp) internal view returns (bytes memory) {
        uint256 dow = BokkyPooBahsDateTimeLibrary.getDayOfWeek(timestamp);
        if (dow == 7) return bytes(".el10,");

        return abi.encodePacked(".el1", dow.toString(), ",");
    }

    function monthClass(uint256 month) internal view returns (bytes memory) {
        if (month > 7) {
            return abi.encodePacked(".el3", (month - 8).toString());
        }

        return abi.encodePacked(".el2", (month - 1).toString());
    }

    function dayClass(uint256 day) internal view returns (bytes memory) {
        if (day < 3) {
            return abi.encodePacked(",.el3", (day + 4).toString());
        }

        uint256 dayIdx = (day - 3) % 7;
        uint256 dayRow = (day - 3) / 7 + 4;

        return abi.encodePacked(",.el", dayRow.toString(), dayIdx.toString());
    }

    function hourClass(uint256 hour) internal view returns (bytes memory) {
        if (hour < 6) {
            return abi.encodePacked(",.el8", (hour + 1).toString());
        }

        uint256 meridianHour = hour % 12;

        if (meridianHour < 6) {
            return abi.encodePacked(",.el8", (meridianHour + 1).toString());
        }

        return abi.encodePacked(",.el9", (meridianHour - 6).toString());
    }

    function minuteClass(uint256 minute) internal view returns (bytes memory) {
        if (minute == 0) {
            return bytes(",.el96");
        }

        uint256 minuteIdx = (minute - 1) % 7;
        uint256 minuteRow = (minute - 1) / 7 + 10;

        return abi.encodePacked(",.el", minuteRow.toString(), minuteIdx.toString());
    }

    function secondClass(uint256 second) internal view returns (bytes memory) {
        if (second < 4) {
            return abi.encodePacked(",.el18", (second + 3).toString());
        }

        uint256 secondIdx = (second - 4) % 7;
        uint256 secondRow = (second - 4) / 7 + 19;

        return abi.encodePacked(",.el", secondRow.toString(), secondIdx.toString());
    }
}
