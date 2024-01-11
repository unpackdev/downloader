// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./IBridge.sol";
import "./IBridgeManager.sol";

contract BridgeManager is OwnableUpgradeable, ReentrancyGuardUpgradeable, IBridgeManager {
    // address of the bridge using bridge id
    mapping(uint256 => address) public bridgeAddress;

    event BridgeAddressUpdate(uint256 bridgeId, address bridgeAddress);
    // supported networks for the bridge id
    // bridgeId => networkId => isSupported
    mapping(uint256 => mapping(uint256 => bool)) public supportedNetworks;

    event SupportedNetworkUpdate(uint256 bridgeId, uint256 networkId, bool isSupported);

    // @notice Initialize function to set up the contract
    // @dev it should be called immediately after deploy
    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    function transferERC20(
        uint256 _bridgeId,
        uint256 _destinationNetworkId,
        address _tokenIn,
        uint256 _amount,
        address _destinationAddress,
        bytes calldata _data
    ) external override nonReentrant {
        require(bridgeAddress[_bridgeId] != address(0), "INVALID BRIDGE ID");
        require(
            supportedNetworks[_bridgeId][_destinationNetworkId] == true,
            "NETWORK NOT SUPPORTED"
        );

        IBridge bridge = IBridge(bridgeAddress[_bridgeId]);
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_tokenIn),
            msg.sender,
            address(bridge),
            _amount
        );
        bridge.transferERC20(_destinationNetworkId, _tokenIn, _amount, _destinationAddress, _data);
    }

    function transferNative(
        uint256 _bridgeId,
        uint256 _destinationNetworkId,
        uint256 _amount,
        address _destinationAddress,
        bytes calldata _data
    ) external payable nonReentrant {
        require(bridgeAddress[_bridgeId] != address(0), "INVALID BRIDGE ID");
        require(
            supportedNetworks[_bridgeId][_destinationNetworkId] == true,
            "NETWORK NOT SUPPORTED"
        );

        IBridge bridge = IBridge(bridgeAddress[_bridgeId]);
        bridge.transferNative{value: msg.value}(
            _destinationNetworkId,
            _amount,
            _destinationAddress,
            _data
        );
    }

    function setBridgeAddress(uint256 _bridgeId, address _address) external onlyOwner {
        require(_bridgeId != 0, "INVALID BRIDGE ID");
        bridgeAddress[_bridgeId] = _address;
        emit BridgeAddressUpdate(_bridgeId, _address);
    }

    function setSupportedNetwork(
        uint256 _bridgeId,
        uint256 _networkId,
        bool _isSupported
    ) external onlyOwner {
        require(_bridgeId != 0, "INVALID BRIDGE ID");
        require(_networkId != 0, "INVALID NETWORK ID");
        supportedNetworks[_bridgeId][_networkId] = _isSupported;

        emit SupportedNetworkUpdate(_bridgeId, _networkId, _isSupported);
    }

    function getBridgeAddress(uint256 _bridgeId) external view override returns (address) {
        return bridgeAddress[_bridgeId];
    }

    function isNetworkSupported(uint256 _bridgeId, uint256 _networkId)
        external
        view
        override
        returns (bool)
    {
        return supportedNetworks[_bridgeId][_networkId];
    }
}
