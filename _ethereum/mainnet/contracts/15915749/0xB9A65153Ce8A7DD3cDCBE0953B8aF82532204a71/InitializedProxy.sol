pragma solidity ^0.8.0;

import "./SettingStorage.sol";
import "./Proxy.sol";

/**
 * @title InitializedProxy
 * @author 0xkongamoto
 */
contract InitializedProxy is SettingStorage, Proxy {
    // ======== Constructor =========
    constructor(address _settings) SettingStorage(_settings) {}

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation()
        internal
        view
        virtual
        override
        returns (address impl)
    {
        return settings;
    }
}
