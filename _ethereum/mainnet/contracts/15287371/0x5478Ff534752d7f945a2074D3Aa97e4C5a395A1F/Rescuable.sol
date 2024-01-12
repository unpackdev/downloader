// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./ISRC20.sol";
import "./Affinity.sol";

contract Rescuable is Affinity {
    constructor(address _SAVIOR) public Affinity(_SAVIOR) {}

    function killSelf() public isKeeper {
        selfdestruct(msg.sender);
    }
}
