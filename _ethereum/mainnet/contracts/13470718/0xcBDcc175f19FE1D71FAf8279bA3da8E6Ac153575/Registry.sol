/// @author Hapi Finance Team
/// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

import "./Ownable.sol";

/** @title Will */
contract Registry is Ownable {
    // If the Registry has been set up yet
    bool _initialized;

    // Proxy contract address to verify calls
    address public proxy;

    // Contracts containing implementation logic
    address[] public implementations;

    // What implementation version each user is running on
    mapping(address => uint256) versions;

    /// Constructor
    constructor() Ownable() {
        // Start with address 0 as v0 - as that is the base for the mapping
        implementations.push(address(0));
        proxy = address(0);
        _initialized = false;
    }

    /// View functions

    /** @notice Gets the implementation for the given sender
     * @dev If version for sender is 0, send latest implementation.
     * @param sender the sender of the call to the proxy
     * @return address of the implementation version for the sender
     */
    function getImplementation(address sender)
        public
        view
        onlyProxy
        initialized
        returns (address)
    {
        uint256 version = versions[sender];
        if (version == 0) {
            version = implementations.length - 1;
        }
        return implementations[version];
    }

    /** @notice Gets the latest implementation contract
     * @return address of the latest implementation contract
     */
    function getLatestImplementation()
        public
        view
        initialized
        returns (address)
    {
        return implementations[implementations.length - 1];
    }

    /** @notice Gets implementation for user, for admin/notification usage. limited to owner
     * @dev If version for sender is 0, send latest implementation.
     * @param user the user whose implementation to look up
     * @return address of the implementation version for the user
     */
    function getImplementationForUser(address user)
        public
        view
        onlyOwner
        initialized
        returns (address)
    {
        uint256 version = versions[user];
        if (version == 0) {
            version = implementations.length - 1;
        }
        return implementations[version];
    }

    /// Update functions

    /** @notice initializes registry once and only once
     * @param newProxy The address of the new proxy contract
     * @param implementation The address of the initial implementation
     */
    function initialize(address newProxy, address implementation)
        public
        onlyOwner
    {
        require(
            _initialized == false,
            "Initialize may only be called once to ensure the proxy can never be switched."
        );
        proxy = newProxy;
        implementations.push(implementation);
        _initialized = true;
    }

    /** @notice Updates the implementation
     * @param newImplementation The address of the new implementation contract
     */
    function register(address newImplementation) public onlyOwner initialized {
        implementations.push(newImplementation);
    }

    /** @notice Upgrades the sender's contract to the latest implementation
     * @param sender the sender of the call to the proxy
     */
    function upgrade(address sender) public onlyProxy initialized {
        versions[sender] = implementations.length - 1;
    }

    /** @notice Upgrades the sender's contract to the latest implementation
     * @param sender the sender of the call to the proxy
     * @param version the version of the implementation to upgrade to
     */
    function upgradeToVersion(address sender, uint256 version)
        public
        onlyProxy
        initialized
    {
        versions[sender] = version;
    }

    /// Modifiers

    /** @notice Restricts method to be called only by the proxy
     */
    modifier onlyProxy() {
        require(
            msg.sender == proxy,
            "This method is restricted to the proxy. Ensure initialize has been called, and you are calling from the proxy."
        );
        _;
    }

    /** @notice Restricts method to be called only once initialized
     */
    modifier initialized() {
        require(
            _initialized == true,
            "Please initialize this contract first by calling 'initialize()'"
        );
        _;
    }
}
