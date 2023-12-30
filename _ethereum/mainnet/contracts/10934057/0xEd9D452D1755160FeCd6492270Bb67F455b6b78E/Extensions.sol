pragma solidity ^0.6.2;

contract Extensions {
    function convertIntToUint(int a) internal pure returns(uint) {
        if (a >= 0) {
            return uint(a);
        }
        return uint(a * -1);
    }
}