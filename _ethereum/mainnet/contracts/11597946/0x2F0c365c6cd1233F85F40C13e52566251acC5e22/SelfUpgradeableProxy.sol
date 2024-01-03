// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./UpgradeableProxy.sol";

/**
 * @dev Upgradeable Proxy that can only be upgraded from external calls from itself.
 *
 * NOTE: The contract implementation delegate must have the ability to call the upgradeTo functions from itself.
 */
contract SelfUpgradeableProxy is UpgradeableProxy {
    constructor(address _logic, bytes memory _data)
        public
        payable
        UpgradeableProxy(_logic, _data)
    {}

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the contract itself can call this function.
     */
    function upgradeTo(address newImplementation) external onlySelf {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the contract itself can call this function.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        external
        payable
        onlySelf
    {
        _upgradeTo(newImplementation);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newImplementation.delegatecall(data);
        require(success);
    }

    /**
     * @dev reverts if caller is not this contract
     */
    modifier onlySelf() {
        require(
            msg.sender == address(this),
            "SelfUpgradeableProxy: Caller not self"
        );
        _;
    }
}
