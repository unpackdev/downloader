//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DragonsVault.sol";

contract TeamVault is DragonsVault {
    constructor(address _tokenAddress)
        DragonsVault("Team", _tokenAddress)
    {}
}
