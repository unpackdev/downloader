// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./WhitelistAdminRole.sol";

contract WhitelistCrowdsale is Crowdsale, WhitelistAdminRole {
    address public whitelister;
    bool public whitelistEnabled = true;

    constructor(address _whitelister) public {
        whitelister = _whitelister;
    }

    function isWhitelisted(address _address) external view returns (bool) {
    	return IWhitelister(whitelister).whitelisted(_address);
    }

    function validateWhitelisted(address beneficiary) internal view returns (bool) {
        return !whitelistEnabled || this.isWhitelisted(beneficiary);
    }

    function toggleWhitelistEnabled() external onlyWhitelistAdmin {
        whitelistEnabled = !whitelistEnabled;
    }
}

interface IWhitelister {
    function whitelisted(address _address) external view returns (bool);
}
