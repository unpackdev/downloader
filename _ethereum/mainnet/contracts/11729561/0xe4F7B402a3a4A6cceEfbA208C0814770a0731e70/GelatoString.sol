// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function returnWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_tracingInfo, _error));
    }
}
