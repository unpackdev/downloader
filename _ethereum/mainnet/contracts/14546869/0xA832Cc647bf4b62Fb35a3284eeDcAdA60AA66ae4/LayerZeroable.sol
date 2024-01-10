pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroUserApplicationConfig.sol";

abstract contract LayerZeroable is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    ILayerZeroEndpoint public layerZeroEndpoint;
    mapping(uint16 => bytes) public remotes;

    uint256 public destGasAmount = 300000;

    function setLayerZeroEndpoint(address _layerZeroEndpoint)
        external
        onlyOwner
    {
        layerZeroEndpoint = ILayerZeroEndpoint(_layerZeroEndpoint);
    }

    function setRemote(uint16 _chainId, bytes calldata _remoteAddress)
        external
        onlyOwner
    {
        remotes[_chainId] = _remoteAddress;
    }

    function setConfig(
        uint16, /*_version*/
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        layerZeroEndpoint.setConfig(
            layerZeroEndpoint.getSendVersion(address(this)),
            _chainId,
            _configType,
            _config
        );
    }

    function setSendVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setSendVersion(version);
    }

    function setReceiveVersion(uint16 version) external override onlyOwner {
        layerZeroEndpoint.setReceiveVersion(version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        layerZeroEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    function setDestGasAmount(uint256 _amount) external onlyOwner {
        destGasAmount = _amount;
    }

    function _bytesToAddress(bytes memory bys)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}