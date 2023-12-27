// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";

abstract contract OptimizedLzApp is Ownable, ILayerZeroReceiver {
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint16 => uint256) public gasLimitLookup;

    uint256 public defaultGasLimit = 20_000;

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    // Do nothing
    function lzReceive(
        uint16,
        bytes calldata,
        uint64,
        bytes calldata
    ) public virtual override {
        return;
    }

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        bytes memory _adapterParams,
        uint _nativeFee
    ) internal virtual {
        bytes memory trustedRemote = getTrusted(_dstChainId);
        lzEndpoint.send{value: _nativeFee}(_dstChainId, trustedRemote, _payload, _refundAddress, address(0), _adapterParams);
    }

    function getTrusted(uint16 _dstChainId) internal view returns (bytes memory) {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        if (trustedRemote.length == 0) {
            return abi.encodePacked(address(this), address(this));
        } else {
            return trustedRemote;
        }
    }

    function getGasLimit(uint16 _dstChainId) internal view returns (uint256) {
        uint256 gasLimit = gasLimitLookup[_dstChainId];
        if (gasLimit == 0) {
            return defaultGasLimit;
        } else {
            return gasLimit;
        }
    }

    function setTrusted(
        uint16[] calldata _remoteChainIds, 
        address[] calldata _remoteAddresses
    ) external onlyOwner {
        require(_remoteChainIds.length == _remoteAddresses.length, "Length Mismatch");

        for (uint i; i < _remoteChainIds.length; i++) {
            trustedRemoteLookup[_remoteChainIds[i]] = abi.encodePacked(_remoteAddresses[i], address(this));
        }
    }

    function setGasLimit(
        uint16[] calldata _remoteChainIds, 
        uint256[] calldata _gasLimits
    ) external onlyOwner {
        require(_remoteChainIds.length == _gasLimits.length, "Length Mismatch");

        for (uint i; i < _remoteChainIds.length; i++) {
            gasLimitLookup[_remoteChainIds[i]] = _gasLimits[i];
        }
    }

    function setDefaultGasLimit(uint256 _defaultGasLimit) external onlyOwner {
        defaultGasLimit = _defaultGasLimit;
    }

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint _configType,
        bytes calldata _config
    ) external onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }
}