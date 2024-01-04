// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20PresetMinterPauser.sol";

contract RiftToken is ERC20PresetMinterPauser {
    constructor (
        string memory name,
        string memory symbol
    ) public payable ERC20PresetMinterPauser(name, symbol) { }

    function removeMinterRole(address minter) public {
          revokeRole(MINTER_ROLE, minter);
    }
}