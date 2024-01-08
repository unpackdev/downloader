//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DragonsVault.sol";

contract PlayToEarnVault is DragonsVault {
    constructor(address _tokenAddress)
        DragonsVault("PlayToEarn", _tokenAddress)
    {}
}
