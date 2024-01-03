// SPDX-License-Identifier: ISC

pragma solidity ^0.7.5;

contract AllUsedERC721Methods {
    function name() public pure returns (string memory) {
        return 'AllUsedERC721Methods';
    }

    function symbol() public pure returns (string memory) {
        return 'ALLERC721';
    }

    function totalSupply() public pure returns (uint256) {
        return 10**9;
    }

    function supportsInterface(bytes4 interfaceID)
        external
        pure
        returns (bool)
    {
        return true;
    }
}
