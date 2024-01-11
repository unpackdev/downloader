// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {
    function getIntAndDigit(uint256 _number)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 n1 = _number / (10**18);
        uint256 n2 = (_number - n1 * 10**18) / (10**17);
        uint256 n3 = (_number - n1 * 10**18 - n2 * 10**17) / (10**16);
        return (n1, n2, n3);
    }

    function _daysToDate(uint256 _days)
        private
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + 2440588;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / 86400
        );
        return (year, month, day);
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
