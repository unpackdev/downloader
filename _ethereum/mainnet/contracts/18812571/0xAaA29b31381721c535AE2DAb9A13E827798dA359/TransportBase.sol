// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.15;

import "./ITransport.sol";
import "./VaultParentProxy.sol";
import "./VaultParent.sol";

import "./VaultBaseExternal.sol";
import "./IVaultRiskProfile.sol";
import "./Accountant.sol";
import "./Registry.sol";
import "./TransportStorage.sol";
import "./ITransport.sol";

import "./ILayerZeroEndpoint.sol";

import "./SafeOwnable.sol";

import "./Call.sol";

abstract contract TransportBase is SafeOwnable, ITransport {
    modifier onlyVault() {
        require(_registry().isVault(msg.sender), 'not child vault');
        _;
    }

    modifier whenNotPaused() {
        require(!_registry().paused(), 'paused');
        _;
    }

    receive() external payable {}

    function initialize(
        address __registry,
        address __lzEndpoint,
        address __stargateRouter
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.registry = Registry(__registry);
        l.lzEndpoint = ILayerZeroEndpoint(__lzEndpoint);
        l.stargateRouter = __stargateRouter;
    }

    function createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) external payable whenNotPaused returns (address deployment) {
        require(msg.value >= _vaultCreationFee(), 'insufficient fee');
        (bool sent, ) = _registry().protocolTreasury().call{ value: msg.value }(
            ''
        );
        require(sent, 'Failed to process create vault fee');
        return
            _createParentVault(
                name,
                symbol,
                manager,
                streamingFee,
                performanceFee,
                riskProfile
            );
    }

    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
    }

    function setSGAssetToSrcPoolId(
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToSrcPoolId[asset] = poolId;
    }

    function setSGAssetToDstPoolId(
        uint16 chainId,
        address asset,
        uint poolId
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.stargateAssetToDstPoolId[chainId][asset] = poolId;
    }

    function setGasUsage(
        uint16 chainId,
        GasFunctionType gasUsageType,
        uint gas
    ) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.gasUsage[chainId][gasUsageType] = gas;
    }

    function setReturnMessageCost(uint16 chainId, uint cost) external {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.returnMessageCosts[chainId] = cost;
    }

    function setBridgeApprovalCancellationTime(uint time) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.bridgeApprovalCancellationTime = time;
    }

    function setVaultCreationFee(uint fee) external onlyOwner {
        TransportStorage.Layout storage l = TransportStorage.layout();
        l.vaultCreationFee = fee;
    }

    function registry() external view returns (Registry) {
        return _registry();
    }

    function bridgeApprovalCancellationTime() external view returns (uint256) {
        return _bridgeApprovalCancellationTime();
    }

    function lzEndpoint() external view returns (ILayerZeroEndpoint) {
        return _lzEndpoint();
    }

    function trustedRemoteLookup(
        uint16 remoteChainId
    ) external view returns (bytes memory) {
        return _trustedRemoteLookup(remoteChainId);
    }

    function stargateRouter() external view returns (address) {
        return _stargateRouter();
    }

    function stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToDstPoolId(dstChainId, srcBridgeToken);
    }

    function stargateAssetToSrcPoolId(
        address bridgeToken
    ) external view returns (uint256) {
        return _stargateAssetToSrcPoolId(bridgeToken);
    }

    function getGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) external view returns (uint) {
        return _destinationGasUsage(chainId, gasFunctionType);
    }

    function returnMessageCost(uint16 chainId) external view returns (uint) {
        return _returnMessageCost(chainId);
    }

    function vaultCreationFee() external view returns (uint) {
        return _vaultCreationFee();
    }

    // For backwards compatibility use to be a constant
    function CREATE_VAULT_FEE() external view returns (uint) {
        return _vaultCreationFee();
    }

    /// Create Parent Vault
    function _createParentVault(
        string memory name,
        string memory symbol,
        address manager,
        uint streamingFee,
        uint performanceFee,
        VaultRiskProfile riskProfile
    ) internal returns (address deployment) {
        require(
            _registry().parentVaultDiamond() != address(0),
            'not parent chain'
        );

        deployment = address(
            new VaultParentProxy(_registry().parentVaultDiamond())
        );

        VaultParent(payable(deployment)).initialize(
            name,
            symbol,
            manager,
            streamingFee,
            performanceFee,
            riskProfile,
            _registry()
        );

        _registry().addVaultParent(deployment);

        emit VaultParentCreated(deployment);
        _registry().emitEvent();
    }

    function _stargateAssetToSrcPoolId(
        address bridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToSrcPoolId[bridgeToken];
    }

    function _stargateAssetToDstPoolId(
        uint16 dstChainId,
        address srcBridgeToken
    ) internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateAssetToDstPoolId[dstChainId][srcBridgeToken];
    }

    function _bridgeApprovalCancellationTime() internal view returns (uint256) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.bridgeApprovalCancellationTime;
    }

    function _trustedRemoteLookup(
        uint16 remoteChainId
    ) internal view returns (bytes memory) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.trustedRemoteLookup[remoteChainId];
    }

    function _lzEndpoint() internal view returns (ILayerZeroEndpoint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.lzEndpoint;
    }

    function _stargateRouter() internal view returns (address) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.stargateRouter;
    }

    function _destinationGasUsage(
        uint16 chainId,
        GasFunctionType gasFunctionType
    ) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.gasUsage[chainId][gasFunctionType];
    }

    function _registry() internal view returns (Registry) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.registry;
    }

    function _returnMessageCost(uint16 chainId) internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.returnMessageCosts[chainId];
    }

    function _vaultCreationFee() internal view returns (uint) {
        TransportStorage.Layout storage l = TransportStorage.layout();
        return l.vaultCreationFee;
    }

    function _getTrustedRemoteDestination(
        uint16 dstChainId
    ) internal view returns (address dstAddr) {
        bytes memory trustedRemote = _trustedRemoteLookup(dstChainId);
        require(
            trustedRemote.length != 0,
            'LzApp: destination chain is not a trusted source'
        );
        assembly {
            dstAddr := mload(add(trustedRemote, 20))
        }
    }
}
