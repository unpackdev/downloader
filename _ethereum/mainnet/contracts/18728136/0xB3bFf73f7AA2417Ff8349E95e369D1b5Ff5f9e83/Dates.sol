// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

library Dates {

    using Strings for uint256;

    function datetimeToString(uint256 timestamp) 
        internal
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
            = BokkyPooBahsDateTimeLibrary.timestampToDateTime(timestamp);
        return 
            string(
                abi.encodePacked(
                    abi.encodePacked(
                        year.toString(), '/', 
                        month < 10 ? '0' : '', month.toString(), '/', 
                        day < 10 ? '0' : '', day.toString(), ' '
                    ),
                    abi.encodePacked(
                        hour < 10 ? '0' : '', hour.toString(), ':', 
                        minute < 10 ? '0' : '', minute.toString(), ':',
                        second < 10 ? '0' : '',  second.toString()
                    )
                )
            );
    }

    function dateToString(uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        (uint256 year, uint256 month, uint256 day)
            = BokkyPooBahsDateTimeLibrary.timestampToDate(timestamp);
        return 
            string(
                abi.encodePacked(
                    year.toString(), '/', 
                    month < 10 ? '0' : '', month.toString(), '/', 
                    day < 10 ? '0' : '', day.toString()
                )
            );
    }

}