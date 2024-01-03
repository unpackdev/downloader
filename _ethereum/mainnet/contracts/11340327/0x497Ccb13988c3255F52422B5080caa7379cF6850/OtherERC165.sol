// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;

contract OtherERC165 {
    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return false;
    }
}
