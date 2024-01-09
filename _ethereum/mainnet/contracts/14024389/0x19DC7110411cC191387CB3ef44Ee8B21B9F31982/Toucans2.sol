// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Toucans.sol";

contract Toucans2 is Toucans {
    function claim(uint256 /*index*/, address /*account*/, bytes32[] calldata /*proof*/)
    external override pure
    {
        revert("disabled");
    }

    function mintAdmin(address account, uint256 count)
    external
        onlyOwner()
        onlyRemaining(count)
    {
        for (uint256 i = 0; i < count; ++i) {
            _mint(account);
        }
    }
}
