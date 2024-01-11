// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.14;

import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./VestedToken.sol";

contract FocusToken is VestedToken, ERC20Permit, Ownable {
    constructor() ERC20("Focus", "FOTO") ERC20Permit("Focus") {
        _mint(0x1e1703F48d0A36f13B8135606D17Bb81f948fc65, 100000000 ether);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(VestedToken, ERC20) {
        VestedToken._afterTokenTransfer(from, to, amount);
    }

    function setupVestingSchedule(
        uint256 cliff,
        uint256 cliffAmount,
        uint256 duration,
        address vestingAdmin
    ) external onlyOwner {
        _setupSchedule(cliff, cliffAmount, duration, vestingAdmin);
    }

    function excludeVesting(address account, bool exclude) external onlyOwner {
        recipientWhitelist[account] = exclude;
    }
}
