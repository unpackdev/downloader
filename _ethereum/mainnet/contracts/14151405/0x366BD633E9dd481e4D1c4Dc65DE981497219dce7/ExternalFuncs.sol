// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ABDKMath64x64.sol";
import "Strings.sol";

library ExternalFuncs {
    // from here https://medium.com/coinmonks/math-in-solidity-part-4-compound-interest-512d9e13041b
    /*
        function pow (int128 x, uint n)
        public pure returns (int128 r) {
            r = ABDKMath64x64.fromUInt (1);
            while (n > 0) {
                if (n % 2 == 1) {
                    r = ABDKMath64x64.mul (r, x);
                    n -= 1;
                } else {
                    x = ABDKMath64x64.mul (x, x);
                    n /= 2;
                }
            }
        }
    */

    function compound(
        uint256 principal,
        uint256 ratio,
        uint256 n
    ) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                ABDKMath64x64.pow( //pow - original code
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(ratio, 10**4)
                    ), //(1+r), where r is allowed to be one hundredth of a percent, ie 5/100/100
                    n
                ), //(1+r)^n
                principal
            ); //A_0 * (1+r)^n
    }

    function Today() public view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function isStakeSizeOk(uint256 amount, uint256 decimals)
        public
        pure
        returns (bool)
    {
        return
            amount == 1000 * 10**decimals ||
            amount == 3000 * 10**decimals ||
            amount == 5000 * 10**decimals ||
            amount == 10000 * 10**decimals ||
            amount == 20000 * 10**decimals ||
            amount == 50000 * 10**decimals ||
            amount == 100000 * 10**decimals ||
            amount == 250000 * 10**decimals ||
            amount >= 1000000 * 10**decimals;
    }

    function getErrorMsg(string memory text, uint256 value)
        public
        pure
        returns (string memory)
    {
        string memory _msg = string(
            abi.encodePacked(text, Strings.toString(value))
        );
        return _msg;
    }
}
