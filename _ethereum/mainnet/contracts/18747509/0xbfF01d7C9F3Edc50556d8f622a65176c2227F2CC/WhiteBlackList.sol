// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./AccessControlUpgradeable.sol";
import "./IERC165Upgradeable.sol";
import "./ECDSAUpgradeable.sol";

import "./Errors.sol";

import "./WhiteBlackListBase.sol";
import "./Constants.sol";

contract WhiteBlackList is WhiteBlackListBase {
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev contract initializer
     * @param _registry The address of Registry contract
     */
    // solhint-disable-next-line comprehensive-interface
    function initialize(address _registry) external initializer {
        __WhiteBlackListBase_init(_registry);
    }

    /**
     * @inheritdoc WhiteBlackListBase
     */
    function addAddressToBlacklist(address _address) public override onlyRole(EMERGENCY_ADMIN) {
        _require(accessList[_address] != AccessType.WHITELISTED, Errors.ADDRESS_IS_WHITELISTED.selector);
        _require(_address.code.length > 0, Errors.ADDRESS_IS_NOT_CONTRACT.selector);
        _addAddressToBlacklist(_address);
    }

    /**
     * @inheritdoc WhiteBlackListBase
     */
    function addAddressToWhitelist(address _address) public override onlyRole(MEDIUM_TIMELOCK_ADMIN) {
        _addAddressToWhitelist(_address);
    }
}
