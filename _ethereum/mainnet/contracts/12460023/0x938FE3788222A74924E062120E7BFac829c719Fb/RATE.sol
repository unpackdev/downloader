//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "./BaseUpgradeableMinterPauserERC20.sol";

contract RATE is BaseUpgradeableMinterPauserERC20 {
    /* Constants */
    string private constant NAME = "Polyient";
    string private constant SYMBOL = "RATE";
    uint8 private constant DECIMAL = 18;

    /* Constructor */
    function initialize(address settingsAddress) public override initializer {
        super.initialize(settingsAddress, NAME, SYMBOL, DECIMAL);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(
            _getPlatformSettingsValue(_settingsConsts().RATE_TOKEN_PAUSED()) == 0,
            "RATE_TOKEN_PAUSED"
        );
    }
}
