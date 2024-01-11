//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library CCLib {

    function join2(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function fmulE18(uint256 x, uint256 y) internal pure returns (uint256) {
        return x * y / 1e18;
    }

    function fpowerE18(uint256 x, uint256 power) internal pure returns (uint256) {
        if (power == 0)
            return 1e18;

        uint256 temp = fpowerE18(x, power / 2);
        if ((power % 2) == 0)
            return fmulE18(temp, temp);
        else
            return fmulE18(x, fmulE18(temp, temp));
    }
}
