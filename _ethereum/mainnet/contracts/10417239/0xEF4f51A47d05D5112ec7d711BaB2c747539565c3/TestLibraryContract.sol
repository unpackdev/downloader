/**
 * Verify contract with libraries
*/

pragma solidity ^0.4.16;

library TestLibraryContract {
    function test() returns (address) {
        return address(this);
    }
}