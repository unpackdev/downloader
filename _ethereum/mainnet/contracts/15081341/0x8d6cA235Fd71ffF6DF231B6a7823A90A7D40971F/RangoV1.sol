// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./RangoCBridgeProxy.sol";
import "./RangoThorchainProxy.sol";
import "./RangoMultichainProxy.sol";

/// @title The main contract that users interact with in the source chain
/// @author Uchiha Sasuke
/// @notice It contains all the required functions to swap on-chain or swap + bridge or swap + bridge + swap initiation in a single step
/// @dev To support a new bridge, it inherits from a proxy with the name of that bridge which adds extra function for that specific bridge
/// @dev There are some extra refund functions for admin to get the money back in case of any unwanted problem
/// @dev This contract is being seen via a transparent proxy from openzeppelin
contract RangoV1 is BaseProxyContract, RangoCBridgeProxy, RangoThorchainProxy, RangoMultichainProxy {

    /// @notice Initializes the state of all sub bridges contracts that RangoV1 inherited from
    /// @param _nativeWrappedAddress Address of wrapped token (WETH, WBNB, etc.) on the current chain
    /// @dev It is the initializer function of proxy pattern, and is equivalent to constructor for normal contracts
    function initialize(address _nativeWrappedAddress) public initializer {
        BaseProxyStorage storage baseProxyStorage = getBaseProxyContractStorage();
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();
        ThorchainProxyStorage storage thorchainProxyStorage = getThorchainProxyStorage();
        MultichainProxyStorage storage multichainProxyStorage = getMultichainProxyStorage();
        baseProxyStorage.nativeWrappedAddress = _nativeWrappedAddress;
        baseProxyStorage.feeContractAddress = NULL_ADDRESS;
        cbridgeProxyStorage.rangoCBridgeAddress = NULL_ADDRESS;
        thorchainProxyStorage.rangoThorchainAddress = NULL_ADDRESS;
        multichainProxyStorage.rangoMultichainAddress = NULL_ADDRESS;
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable { }

    /// @notice Returns the list of valid Rango contracts that can call other contracts for the security purpose
    /// @dev This contains the contracts that can call others via messaging protocols, and excludes DEX-only contracts such as Thorchain
    /// @return List of addresses of Rango contracts that can call other contracts
    function getValidRangoContracts() external view returns (address[] memory) {
        CBridgeProxyStorage storage cbridgeProxyStorage = getCBridgeProxyStorage();
        MultichainProxyStorage storage multichainProxyStorage = getMultichainProxyStorage();

        address[] memory whitelist = new address[](3);
        whitelist[0] = address(this);
        whitelist[1] = cbridgeProxyStorage.rangoCBridgeAddress;
        whitelist[2] = multichainProxyStorage.rangoMultichainAddress;

        return whitelist;
    }
}

