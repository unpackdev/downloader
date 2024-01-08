// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.6;

import "./BaseToken.sol";
import "./Governance.sol";
import "./IEIP2612.sol";

contract Baks is Governed, BaseToken {
    event MinterChanged(address indexed minter, address indexed newMinter);

    constructor(address minter) BaseToken("Baks", "BAKS", 18, "1", minter) {}

    function setMinter(address newMinter) external onlyGovernor {
        if (newMinter == address(0)) {
            revert MinterZeroAddress();
        }
        minter = newMinter;
        emit MinterChanged(minter, newMinter);
    }
}
