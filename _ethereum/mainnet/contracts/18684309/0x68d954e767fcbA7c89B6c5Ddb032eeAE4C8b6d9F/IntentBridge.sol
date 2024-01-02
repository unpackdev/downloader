// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./ISpokePool.sol";
import "./IIntentBridge.sol";

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

    enum BridgeType {
        ACROSS
    }

    struct DstChainConfig {
        BridgeType bridgeType;
        address intentBridgeReceiver;
    }

contract IntentBridge is IIntentBridge, Initializable, OwnableUpgradeable {
    address public constant ACROSS_SPOKE_POOL = 0x5c7BCd6E7De5423a257D81B442095A1a6ced35C5;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint16 public constant CHAIN_ID = 1;

    mapping(uint16 => DstChainConfig) public dstChainConfig;

    event BridgeTo(uint16 dstChainId, address dstToken, address from, address to, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init();
    }

    function setDstChainConfig(uint16 _dstChainId, BridgeType _bridgeType, address _intentBridgeReceiver) onlyOwner external {
        require(msg.sender == owner(), "Only owner can call this function");
        dstChainConfig[_dstChainId] = DstChainConfig(_bridgeType, _intentBridgeReceiver);
    }

    function bridgeETH(uint16 _dstChainId, address _dstToken, address _from, address _to, uint256 _amount) external payable override {
        if (dstChainConfig[_dstChainId].bridgeType == BridgeType.ACROSS) {
            _acrossBridgeETH(_dstChainId, _dstToken, _from, _to, _amount);
        } else {
            revert("Invalid bridge type");
        }

        emit BridgeTo(_dstChainId, _dstToken, _from, _to, _amount);
    }

    //INTERNAL FUNCTION

    function _acrossRelayFeePct(uint value) internal view returns (int64) {
        if (value <= 0.1 ether) {
            return int64(uint64(0.0015 ether * 1 ether / value));
        }

        if (value <= 0.5 ether) {
            return int64(uint64(0.0017 ether * 1 ether / value));
        }

        if (value <= 1 ether) {
            return int64(uint64(0.002 ether * 1 ether / value));
        }

        return int64(uint64(0.003 ether * 1 ether / value));
    }

    function _acrossBridgeETH(uint16 _dstChainId, address _dstToken, address _from, address _to, uint256 _amount) internal {
        require(msg.value >= 0.01 ether, "You must send at least 0.01 ether");

        require(msg.value == _amount, "Incorrect amount sent");

        uint time = block.timestamp - uint(1000);
        bytes memory message = abi.encode(_from, _to, _dstToken);

        int64 relayFeePct = _acrossRelayFeePct(msg.value);

        address intentBridgeReceiver = dstChainConfig[_dstChainId].intentBridgeReceiver;

        ISpokePool(ACROSS_SPOKE_POOL).deposit{value: msg.value}(
            intentBridgeReceiver,
            WETH,
            msg.value,
            _dstChainId,
            relayFeePct,
            uint32(block.timestamp - 1000),
            message,
            type(uint256).max
        );
    }

    receive() external payable {
    }
}
