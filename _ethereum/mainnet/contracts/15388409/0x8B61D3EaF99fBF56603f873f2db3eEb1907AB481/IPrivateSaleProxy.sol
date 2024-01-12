//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

interface IPrivateSaleProxy {
    /// @dev Set pause state
    /// @param _pause true:pause or false:resume
    function setProxyPause(bool _pause) external;

    /// @dev Set implementation contract
    /// @param impl New implementation contract address
    function upgradeTo(address impl) external;

    /// @dev view implementation address of the proxy[index]
    /// @return address of the implementation
    function implementation() external view returns (address);

    /// @dev set the implementation address and status of the proxy[index]
    /// @param newImplementation Address of the new implementation.
    /// @param _index index of proxy
    /// @param _alive alive status
    function setImplementation2(
        address newImplementation,
        uint256 _index,
        bool _alive
    ) external;

    /// @dev set alive status of implementation
    /// @param newImplementation Address of the new implementation.
    /// @param _alive alive status
    function setAliveImplementation2(address newImplementation, bool _alive)
        external;

    /// @dev set selectors of Implementation
    /// @param _selectors being added selectors
    /// @param _imp implementation address
    function setSelectorImplementations2(
        bytes4[] calldata _selectors,
        address _imp
    ) external;

    /// @dev set the implementation address and status of the proxy[index]
    /// @param _selector the selector of function
    function getSelectorImplementation2(bytes4 _selector)
        external
        view
    returns (address impl);
}
