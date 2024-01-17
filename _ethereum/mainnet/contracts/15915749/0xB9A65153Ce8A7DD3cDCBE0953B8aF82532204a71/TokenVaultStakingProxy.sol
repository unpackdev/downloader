pragma solidity ^0.8.0;

import "./InitializedProxy.sol";
import "./IImpls.sol";

/**
 * @title InitializedProxy
 * @author 0xkongamoto
 */
contract TokenVaultStakingProxy is InitializedProxy {
    constructor(address _settings)
        InitializedProxy(_settings)
    {}

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
        return IImpls(settings).stakingImpl();
    }
}
