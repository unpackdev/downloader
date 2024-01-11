// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./BaseProxyContract.sol";
import "./RangoCBridgeProxy.sol";
import "./RangoThorchainProxy.sol";
import "./RangoMultichainProxy.sol";

contract RangoV1 is BaseProxyContract, RangoCBridgeProxy, RangoThorchainProxy, RangoMultichainProxy {

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

    receive() external payable { }
}

