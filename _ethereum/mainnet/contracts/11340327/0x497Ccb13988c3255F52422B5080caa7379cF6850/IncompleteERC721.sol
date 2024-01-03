// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;

contract IncompleteERC721 {
    function name() public pure returns (string memory) {
        return 'IncompleteERC721';
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return true;
    }
}
