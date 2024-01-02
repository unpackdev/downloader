pragma solidity ^0.8.19;

import "./Initializable.sol";
import "./Network.sol";
import "./IPRegistry.sol";

error NotDandelionVoting(address dandelionVoting, address expectedDandelionVoting);
error NetworkAlreadyAdded(bytes4 networkId);

contract PRegistry is IPRegistry, Initializable {
    address public dandelionVoting;

    address[] private _supportedHubs;
    uint32[] private _supportedChainIds;
    mapping(bytes4 => address) private _networkIdToHub;
    mapping(bytes4 => uint32) private _networkIdToChainId;

    modifier onlyDandelionVoting() {
        if (msg.sender != dandelionVoting) {
            revert NotDandelionVoting(msg.sender, dandelionVoting);
        }

        _;
    }

    function initialize(address dandelionVoting_) public initializer {
        dandelionVoting = dandelionVoting_;
    }

    // @inheritdoc IPRegistry
    function getChainIdByNetworkId(bytes4 networkId) external view returns (uint32) {
        return _networkIdToChainId[networkId];
    }

    // @inheritdoc IPRegistry
    function getHubByNetworkId(bytes4 networkId) external view returns (address) {
        return _networkIdToHub[networkId];
    }

    // @inheritdoc IPRegistry
    function getSupportedChainIds() external view returns (uint32[] memory) {
        return _supportedChainIds;
    }

    // @inheritdoc IPRegistry
    function getSupportedHubs() external view returns (address[] memory) {
        return _supportedHubs;
    }

    // @inheritdoc IPRegistry
    function isChainIdSupported(uint32 chainId) external view returns (bool) {
        bytes4 networkId = Network.getNetworkIdFromChainId(chainId);
        return isNetworkIdSupported(networkId);
    }

    // @inheritdoc IPRegistry
    function isNetworkIdSupported(bytes4 networkId) public view returns (bool) {
        address hub = _networkIdToHub[networkId];
        return (hub != address(0));
    }

    // @inheritdoc IPRegistry
    function protocolAddNetwork(uint32 chainId, address hub) external onlyDandelionVoting {
        bytes4 networkId = Network.getNetworkIdFromChainId(chainId);

        if (_networkIdToHub[networkId] != address(0)) {
            revert NetworkAlreadyAdded(networkId);
        }

        _supportedHubs.push(hub);
        _supportedChainIds.push(chainId);
        _networkIdToHub[networkId] = hub;
        _networkIdToChainId[networkId] = chainId;
        emit NetworkAdded(networkId, chainId, hub);
    }
}
