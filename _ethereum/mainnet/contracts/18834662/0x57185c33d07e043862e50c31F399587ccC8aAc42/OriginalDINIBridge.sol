// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./LzLib.sol";
import "./DINIBridgeBase.sol";

/// @dev Locks an ERC20 on the source chain and sends LZ message to the remote chain to mint a wrapped token
contract OriginalDINIBridge is DINIBridgeBase {
    using SafeERC20 for IERC20;

    uint256 public constant FEE_DIVISOR = 100000;

    /// @notice Tokens that can be bridged to the remote chain
    mapping(address => bool) public supportedTokens;

    /// @notice Token conversion rates from local decimals (LD) to shared decimals (SD).
    /// E.g., if local decimals is 18 and shared decimals is 6, the conversion rate is 10^12
    mapping(address => uint256) public LDtoSDConversionRate;

    /// @notice Total value locked per each supported token in shared decimals
    mapping(address => uint256) public totalValueLockedSD;

    mapping(address => uint256) feeTotalAmountERC20;

    /// @notice LayerZero id of the remote chain where wrapped tokens are minted
    uint16 public remoteChainId;

    uint256 public fee = 1250;
    uint256 feeAmountThresholdERC20 = 1e3 * (10**6);

    address public feeCollector;

    event SendToken(address token, address from, address to, uint256 amount);
    event ReceiveToken(address token, address to, uint256 amount);
    event SetRemoteChainId(uint16 remoteChainId);
    event RegisterToken(address token);
    event WithdrawFee(address indexed token, address to, uint256 amount);

    constructor(
        address _endpoint,
        uint16 _remoteChainId,
        address _feeCollector
    ) DINIBridgeBase(_endpoint) {
        remoteChainId = _remoteChainId;
        feeCollector = _feeCollector;
    }

    /// @notice Registers a token for bridging
    /// @param token address of the token
    /// @param sharedDecimals number of decimals used for all original tokens mapped to the same wrapped token.
    /// E.g., 6 is shared decimals for USDC on Ethereum, BSC and Polygon
    function registerToken(address token, uint8 sharedDecimals)
        external
        onlyOwner
    {
        require(
            token != address(0),
            "OriginalDINIBridge: invalid token address"
        );
        require(
            !supportedTokens[token],
            "OriginalDINIBridge: token already registered"
        );

        uint8 localDecimals = _getTokenDecimals(token);
        require(
            localDecimals >= sharedDecimals,
            "OriginalDINIBridge: shared decimals must be less than or equal to local decimals"
        );

        supportedTokens[token] = true;
        LDtoSDConversionRate[token] = 10**(localDecimals - sharedDecimals);
        emit RegisterToken(token);
    }

    function setRemoteChainId(uint16 _remoteChainId) external onlyOwner {
        remoteChainId = _remoteChainId;
        emit SetRemoteChainId(_remoteChainId);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setFeeWallet(address _feeCollector) public onlyOwner {
        require(_feeCollector != address(0), "Address 0");
        feeCollector = _feeCollector;
    }

    function setFeeAmountThreshold(uint256 _feeAmountThresholdERC20)
        public
        onlyOwner
    {
        feeAmountThresholdERC20 = _feeAmountThresholdERC20;
    }

    function payERC20Fees(address token) public nonReentrant onlyOwner {
        require(IERC20(token).balanceOf(address(this)) > 0, "No tokens");
        require(
            IERC20(token).balanceOf(address(this)) > feeTotalAmountERC20[token],
            "Not enough tokens"
        );
        IERC20(token).safeTransfer(feeCollector, feeTotalAmountERC20[token]);
        feeTotalAmountERC20[token] = 0;
    }

    function accruedFeeLD(address token) public view returns (uint256) {
        return
            IERC20(token).balanceOf(address(this)) -
            _amountSDtoLD(token, totalValueLockedSD[token]);
    }

    function estimateBridgeFee(bool useZro, bytes calldata adapterParams)
        public
        view
        returns (uint256 nativeFee, uint256 zroFee)
    {
        // Only the payload format matters when estimating fee, not the actual data
        bytes memory payload = abi.encode(
            PT_MINT,
            address(this),
            address(this),
            0
        );
        return
            lzEndpoint.estimateFees(
                remoteChainId,
                address(this),
                payload,
                useZro,
                adapterParams
            );
    }

    /// @notice Bridges ERC20 to the remote chain
    /// @dev Locks an ERC20 on the source chain and sends LZ message to the remote chain to mint a wrapped token
    function bridge(
        address token,
        uint256 amountLD,
        address to,
        LzLib.CallParams calldata callParams,
        bytes memory adapterParams
    ) external payable nonReentrant {
        require(
            supportedTokens[token],
            "OriginalDINIBridge: token is not supported"
        );

        // Supports tokens with transfer fee
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountLD);
        uint256 balanceAfter = IERC20(token).balanceOf(address(this));
        (uint256 amountWithoutDustLD, uint256 dust) = _removeDust(
            token,
            balanceAfter - balanceBefore
        );

        // return dust to the sender
        if (dust > 0) {
            IERC20(token).safeTransfer(msg.sender, dust);
        }

        _bridge(
            token,
            amountWithoutDustLD,
            to,
            msg.value,
            callParams,
            adapterParams
        );
    }

    function _bridge(
        address token,
        uint256 amountLD,
        address to,
        uint256 nativeFee,
        LzLib.CallParams calldata callParams,
        bytes memory adapterParams
    ) private {
        require(to != address(0), "OriginalDINIBridge: invalid to");
        _checkAdapterParams(remoteChainId, PT_MINT, adapterParams);

        uint256 amountSD = _amountLDtoSD(token, amountLD);
        require(amountSD > 0, "OriginalDINIBridge: invalid amount");

        totalValueLockedSD[token] += amountSD;
        bytes memory payload = abi.encode(PT_MINT, token, to, amountSD);
        _lzSend(
            remoteChainId,
            payload,
            callParams.refundAddress,
            callParams.zroPaymentAddress,
            adapterParams,
            nativeFee
        );
        emit SendToken(token, msg.sender, to, amountLD);
    }

    function withdrawFee(
        address token,
        address to,
        uint256 amountLD
    ) public onlyOwner {
        uint256 feeLD = accruedFeeLD(token);
        require(
            amountLD <= feeLD,
            "OriginalDINIBridge: not enough fees collected"
        );

        IERC20(token).safeTransfer(to, amountLD);
        emit WithdrawFee(token, to, amountLD);
    }

    /// @notice Receives ERC20 tokens or ETH from the remote chain
    /// @dev Unlocks locked ERC20 tokens or ETH in response to LZ message from the remote chain
    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory,
        uint64,
        bytes memory payload
    ) internal virtual override {
        require(
            srcChainId == remoteChainId,
            "OriginalDINIBridge: invalid source chain id"
        );

        (
            uint8 packetType,
            address token,
            address to,
            uint256 withdrawalAmountSD,
            uint256 totalAmountSD
        ) = abi.decode(payload, (uint8, address, address, uint256, uint256));
        require(
            packetType == PT_UNLOCK,
            "OriginalDINIBridge: unknown packet type"
        );
        require(
            supportedTokens[token],
            "OriginalDINIBridge: token is not supported"
        );

        totalValueLockedSD[token] -= totalAmountSD;
        uint256 withdrawalAmountLD = _amountSDtoLD(token, withdrawalAmountSD);

        IERC20(token).safeTransfer(to, withdrawalAmountLD);
        emit ReceiveToken(token, to, withdrawalAmountLD);
    }

    function _getTokenDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature("decimals()")
        );
        require(success, "OriginalDINIBridge: failed to get token decimals");
        return abi.decode(data, (uint8));
    }

    function _amountSDtoLD(address token, uint256 amountSD)
        internal
        view
        returns (uint256)
    {
        return amountSD * LDtoSDConversionRate[token];
    }

    function _amountLDtoSD(address token, uint256 amountLD)
        internal
        view
        returns (uint256)
    {
        return amountLD / LDtoSDConversionRate[token];
    }

    function _removeDust(address token, uint256 amountLD)
        internal
        view
        returns (uint256 amountWithoutDustLD, uint256 dust)
    {
        dust = amountLD % LDtoSDConversionRate[token];
        amountWithoutDustLD = amountLD - dust;
    }

    function _getAndPayFee(address token, uint256 amount)
        internal
        returns (uint256 feeAmount)
    {
        // move all the tokens to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // calculate the fee
        feeAmount = (amount * fee) / FEE_DIVISOR;

        feeTotalAmountERC20[token] += feeAmount;
        if (feeTotalAmountERC20[token] >= feeAmountThresholdERC20) {
            (bool success, ) = feeCollector.call{value: (feeTotalAmountERC20[token])}(
                ""
            );
            require(success, "Send fee failed");
            feeTotalAmountERC20[token] = 0;
        }

        return feeAmount;
    }
}
