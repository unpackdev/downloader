//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

//import "./IStakeProxyStorage.sol";
import "./IStakeFactory.sol";
import "./IStakeRegistry.sol";
import "./IStakeVaultFactory.sol";

/// @title The storage of StakeProxy
contract StakeProxyStorage {
    /// @dev stakeRegistry
    IStakeRegistry public stakeRegistry;

    /// @dev stakeFactory
    IStakeFactory public stakeFactory;

    /// @dev stakeVaultFactory
    IStakeVaultFactory public stakeVaultFactory;

    /// @dev TOS address
    address public tos;

    /// @dev TON address in Tokamak
    address public ton;

    /// @dev WTON address in Tokamak
    address public wton;

    /// @dev Depositmanager address in Tokamak
    address public depositManager;

    /// @dev SeigManager address in Tokamak
    address public seigManager;

    /// @dev flag for pause proxy
    bool public pauseProxy;

    /// @dev implementation of proxy index
    mapping(uint256 => address) public proxyImplementation;

    mapping(address => bool) public aliveImplementation;

    mapping(bytes4 => address) public selectorImplementation;
}
