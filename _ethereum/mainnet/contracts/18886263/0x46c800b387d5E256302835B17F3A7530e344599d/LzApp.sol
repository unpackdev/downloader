// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./BaseLzApp.sol";
import "./ContractRoles.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is BaseLzApp, ContractRoles {
    constructor(address _admin) ContractRoles(_admin) {
        _grantRole(ADMIN_ROLE, _admin);
    }

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyRole(ADMIN_ROLE) {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(
        uint16 _version
    ) external override onlyRole(ADMIN_ROLE) {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(
        uint16 _version
    ) external override onlyRole(ADMIN_ROLE) {
        lzEndpoint.setReceiveVersion(_version);
    }

    function setLzEndpoint(address _lzEndpoint) external onlyRole(ADMIN_ROLE) {
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
    }

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external override onlyRole(ADMIN_ROLE) {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(
        uint16 _srcChainId,
        bytes calldata _srcAddress
    ) external onlyRole(ADMIN_ROLE) {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function setTrustedRemoteAddress(
        uint16 _remoteChainId,
        bytes calldata _remoteAddress
    ) external onlyRole(ADMIN_ROLE) {
        trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
            _remoteAddress,
            address(this)
        );
        emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
    }

    function setPrecrime(address _precrime) external onlyRole(ADMIN_ROLE) {
        precrime = _precrime;
        emit SetPrecrime(_precrime);
    }

    function setMinDstGas(
        uint16 _dstChainId,
        uint16 _packetType,
        uint _minGas
    ) external onlyRole(ADMIN_ROLE) {
        minDstGasLookup[_dstChainId][_packetType] = _minGas;
        emit SetMinDstGas(_dstChainId, _packetType, _minGas);
    }

    // if the size is 0, it means default size limit
    function setPayloadSizeLimit(
        uint16 _dstChainId,
        uint _size
    ) external onlyRole(ADMIN_ROLE) {
        payloadSizeLimitLookup[_dstChainId] = _size;
    }
}
