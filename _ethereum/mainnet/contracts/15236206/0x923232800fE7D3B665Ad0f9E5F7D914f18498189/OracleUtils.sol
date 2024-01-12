// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./StringLib.sol";

library OracleUtils {
    function genRequestURL(
        string memory oracleRequestHost,
        uint16[] memory monthAndDay,
        string memory remaining
    ) internal pure returns (string memory url) {
        url = string(
            abi.encodePacked(
                oracleRequestHost,
                "/api/v1/calc-chart-data-degrees-encrypted?houses=Placidus&zodiac=Krishnamurti&monthAndDay=",
                convertDatetimeToString(monthAndDay),
                "&remaining=",
                remaining
            )
        );
    }

    function convertDatetimeToString(uint16[] memory datetime)
        private
        pure
        returns (string memory res)
    {
        uint16 month = datetime[0];
        uint16 day = datetime[1];

        res = string(
            abi.encodePacked(
                StringLib.uintToString(month),
                ",",
                StringLib.uintToString(day)
            )
        );
    }
}