// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./AccessControl.sol";
import "./Utils.sol";

contract ETHReceiver is AccessControl {
    event Pull(address indexed to, uint256 value);

    receive() external payable {}

    constructor() {
        _setupRole(Utils.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function pull()
        public
        payable
        onlyRole(Utils.STAKE_STAR_ROLE)
        returns (uint256 balance)
    {
        balance = address(this).balance;
        Utils.safeTransferETH(msg.sender, balance);
        emit Pull(msg.sender, balance);
    }
}
