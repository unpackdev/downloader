// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20.sol";
import "./Address.sol";

import "./IZKBridgeReceiver.sol";
import "./IZKBridgeEndpoint.sol";
import "./IL1Bridge.sol";

import "./Pool.sol";

contract Bridge is IZKBridgeReceiver, Initializable, ReentrancyGuardUpgradeable, Pool {
    using SafeERC20 for IERC20;

    IZKBridgeEndpoint public immutable zkBridgeEndpoint;
    IL1Bridge public immutable l1Bridge;

    // chainId -> bridge address, mapping of token bridge contracts on other chains
    mapping(uint16 => address) public bridgeLookup;

    // For two-step bridge management
    bool public pendingBridge;
    uint16 public pendingDstChainId;
    address public pendingBridgeAddress;

    event TransferToken(
        uint64 indexed sequence,
        uint16 indexed dstChainId,
        uint256 indexed poolId,
        address sender,
        address recipient,
        uint256 amount
    );

    event ReceiveToken(
        uint64 indexed sequence, uint16 indexed srcChainId, uint256 indexed poolId, address recipient, uint256 amount
    );

    event MuxTransferInitiated(uint8 indexed bridgeType, address indexed sender);

    event NewPendingBridge(uint16 chainId, address bridge);
    event NewBridge(uint16 chainId, address bridge);

    /// @dev l1Bridge_ could be address(0) when Mux functions are not needed
    constructor(IZKBridgeEndpoint zkBridgeEndpoint_, IL1Bridge l1Bridge_, uint256 NATIVE_TOKEN_POOL_ID_)
        Pool(NATIVE_TOKEN_POOL_ID_)
    {
        require(address(zkBridgeEndpoint_) != address(0), "Bridge: zkBridgeEndpoint is the zero address");
        zkBridgeEndpoint = zkBridgeEndpoint_;
        l1Bridge = l1Bridge_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Admin_init();
    }

    function estimateFee(uint256 poolId, uint16 dstChainId) public view returns (uint256) {
        _checkDstChain(poolId, dstChainId);
        uint256 uaFee = getFee(poolId, dstChainId);
        uint256 zkBridgeFee = zkBridgeEndpoint.estimateFee(dstChainId);
        return uaFee + zkBridgeFee;
    }

    function _transfer(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient, uint256 fee)
        internal
        returns (uint256)
    {
        address dstBridge = bridgeLookup[dstChainId];
        require(dstBridge != address(0), "Bridge: dstChainId does not exist");

        uint256 uaFee = getFee(poolId, dstChainId);
        uint256 zkBridgeFee = zkBridgeEndpoint.estimateFee(dstChainId);
        require(fee >= uaFee + zkBridgeFee, "Bridge: Insufficient Fee");

        uint256 amountSD = _deposit(poolId, dstChainId, amount);

        bytes memory payload = abi.encode(poolId, amountSD, recipient);
        uint64 sequence = zkBridgeEndpoint.send{value: zkBridgeFee}(dstChainId, dstBridge, payload);

        emit TransferToken(sequence, dstChainId, poolId, msg.sender, recipient, amountSD);

        // Returns the actual amount of fees used
        return uaFee + zkBridgeFee;
    }

    /// @notice The main function for sending native token through bridge
    function transferETH(uint16 dstChainId, uint256 amount, address recipient) external payable nonReentrant {
        require(msg.value >= amount, "Bridge: Insufficient ETH");
        _transfer(dstChainId, NATIVE_TOKEN_POOL_ID, amount, recipient, msg.value - amount);
    }

    /// @notice The main function for sending ERC20 tokens through bridge
    function transferToken(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient)
        external
        payable
        nonReentrant
    {
        require(poolId != NATIVE_TOKEN_POOL_ID, "Bridge: Can't transfer token using native token pool ID");
        IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
        _transfer(dstChainId, poolId, amount, recipient, msg.value);
    }

    /// @notice The main function for receiving tokens. Should only be called by zkBridge
    function zkReceive(uint16 srcChainId, address srcAddress, uint64 sequence, bytes calldata payload)
        external
        nonReentrant
    {
        require(msg.sender == address(zkBridgeEndpoint), "Bridge: Not from zkBridgeEndpoint");
        require(srcAddress != address(0) && srcAddress == bridgeLookup[srcChainId], "Bridge: Invalid emitter");

        (uint256 poolId, uint256 amountSD, address recipient) = abi.decode(payload, (uint256, uint256, address));

        uint256 amount = _withdraw(poolId, srcChainId, amountSD);

        if (poolId == NATIVE_TOKEN_POOL_ID) {
            Address.sendValue(payable(recipient), amount);
        } else {
            IERC20(_poolInfo[poolId].token).safeTransfer(recipient, amount);
        }

        emit ReceiveToken(sequence, srcChainId, poolId, recipient, amountSD);
    }

    /// @notice Sending native token through bridge, fallback to l1bridge when limits are triggered
    function transferETHMux(uint16 dstChainId, uint256 amount, address recipient) external payable nonReentrant {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        uint256 refundAmount;
        if (
            _poolInfo[NATIVE_TOKEN_POOL_ID].balance + amount <= _poolInfo[NATIVE_TOKEN_POOL_ID].maxLiquidity
                && amount <= _dstChains[NATIVE_TOKEN_POOL_ID][dstChainId].maxTransferLimit
        ) {
            emit MuxTransferInitiated(1, msg.sender);
            require(msg.value >= amount, "Bridge: Insufficient ETH");
            uint256 fee = _transfer(dstChainId, NATIVE_TOKEN_POOL_ID, amount, recipient, msg.value - amount);
            refundAmount = msg.value - amount - fee;
        } else {
            emit MuxTransferInitiated(2, msg.sender);
            uint256 fee = l1Bridge.fees(dstChainId);
            require(msg.value >= amount + fee, "Bridge: Insufficient ETH");
            l1Bridge.transferETH{value: amount + fee}(dstChainId, amount, recipient);
            refundAmount = msg.value - amount - fee;
        }

        if (refundAmount > 0) {
            Address.sendValue(payable(msg.sender), refundAmount);
        }
    }

    /// @notice Sending ERC20 tokens through bridge, fallback to l1bridge when limits are triggered
    function transferTokenMux(uint16 dstChainId, uint256 poolId, uint256 amount, address recipient)
        external
        payable
        nonReentrant
    {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        require(poolId != NATIVE_TOKEN_POOL_ID, "Bridge: Can't transfer token using native token pool ID");
        address token = _poolInfo[poolId].token;
        require(token != address(0), "Bridge: pool not found");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 refundAmount;
        if (
            _poolInfo[poolId].balance + amount <= _poolInfo[poolId].maxLiquidity
                && amount <= _dstChains[poolId][dstChainId].maxTransferLimit
        ) {
            emit MuxTransferInitiated(1, msg.sender);
            IERC20(_poolInfo[poolId].token).safeTransferFrom(msg.sender, address(this), amount);
            uint256 fee = _transfer(dstChainId, poolId, amount, recipient, msg.value);
            refundAmount = msg.value - fee;
        } else {
            emit MuxTransferInitiated(2, msg.sender);
            uint256 fee = l1Bridge.fees(dstChainId);
            require(msg.value >= fee, "Bridge: Insufficient fee");
            IERC20(token).safeApprove(address(l1Bridge), amount);
            l1Bridge.transferERC20{value: fee}(dstChainId, token, amount, recipient);
            IERC20(token).safeApprove(address(l1Bridge), 0);
            refundAmount = msg.value - fee;
        }

        if (refundAmount > 0) {
            Address.sendValue(payable(msg.sender), refundAmount);
        }
    }

    function estimateFeeMux(uint256 poolId, uint16 dstChainId) external view returns (uint256) {
        require(address(l1Bridge) != address(0), "Bridge: l1Bridge not available");
        uint256 fee = estimateFee(poolId, dstChainId);
        uint256 l1Fee = l1Bridge.fees(dstChainId);
        return fee > l1Fee ? fee : l1Fee;
    }

    /// @notice adding a new dstChain bridge address
    /// @param bridge could be address(0) when deleting a bridge
    function setBridge(uint16 dstChainId, address bridge) external onlyBridgeManager nonReentrant {
        if (bridgeManager != bridgeReviewer) {
            // Two-step bridge management needed
            pendingDstChainId = dstChainId;
            pendingBridgeAddress = bridge;
            pendingBridge = true;
            emit NewPendingBridge(dstChainId, bridge);
        } else {
            // bridgeManager is the same as bridgeReviewer, two-step bridge management not needed
            bridgeLookup[dstChainId] = bridge;
            emit NewBridge(dstChainId, bridge);
        }
    }

    /// @notice approve a new dstChain bridge address
    /// @dev The dstChainId and bridge params are required to prevent front-running attacks
    function approveSetBridge(uint16 dstChainId, address bridge) external onlyBridgeReviewer nonReentrant {
        require(pendingBridge, "Bridge: no pending bridge");
        require(
            dstChainId == pendingDstChainId && bridge == pendingBridgeAddress,
            "Bridge: dstChainId or bridge does not match"
        );
        bridgeLookup[dstChainId] = bridge;
        pendingBridge = false;
        emit NewBridge(dstChainId, bridge);
    }
}
