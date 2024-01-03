// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./Crowdsale.sol";
import "./WhitelistAdminRole.sol";
import "./TimedCrowdsale.sol";

contract WithrawableCrowdsale is Crowdsale, WhitelistAdminRole, TimedCrowdsale {
    address public burnAddr = 0x000000000000000000000000000000000000dEaD;

    function _forwardFunds() internal {
        // Do nothing and keep funds in the Crowdsale.
    }

    function withdrawETH(uint256 amount) public onlyWhitelistAdmin {
        msg.sender.transfer(amount);
    }

    function burnUnsold(uint256 amount) public onlyWhitelistAdmin {
        require(hasClosed(), "WithrawableCrowdsale: crowdsale is not closed yet");
        require(amount <= token().balanceOf(address(this)), "WithrawableCrowdsale: amount is bigger than tokens left");
        token().transfer(burnAddr, amount);
    }
}
