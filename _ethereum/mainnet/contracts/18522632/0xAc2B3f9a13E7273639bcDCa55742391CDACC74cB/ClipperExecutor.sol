// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IReactorCallback.sol";
import "./IReactor.sol";
import "./IValidationCallback.sol";
import "./ReactorStructs.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

struct ClipperSwapParams {
        uint256 packedInput;
        uint256 packedOutput;
        uint256 goodUntil;
        bytes32 r;
        bytes32 vs;
}

interface ClipperCommonInterface {
    function swap(address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external;
    function sellEthForToken(address outputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external payable;
    function sellTokenForEth(address inputToken, uint256 inputAmount, uint256 outputAmount, uint256 goodUntil, address destinationAddress, Signature calldata theSignature, bytes calldata auxiliaryData) external;
    function nTokens() external view returns (uint);
    function tokenAt(uint i) external view returns (address);
}

/// @notice A fill contract that uses Clipper to execute trades
contract ClipperExecutor is IReactorCallback, Ownable {
    using SafeERC20 for IERC20;

    /// @notice thrown if reactorCallback is called with a non-whitelisted filler
    error CallerNotWhitelisted();
    /// @notice thrown if reactorCallback is called by an adress other than the reactor
    error MsgSenderNotReactor();
    error NativeTransferFailed();

    address private immutable CLIPPER_EXCHANGE;
    address private whitelistedCaller;
    IReactor private immutable reactor;
    address constant NATIVE = 0x0000000000000000000000000000000000000000;
    uint256 constant TRANSFER_NATIVE_GAS_LIMIT = 6900;

    modifier onlyWhitelistedCaller() {
        if (msg.sender != whitelistedCaller) {
            revert CallerNotWhitelisted();
        }
        _;
    }

    modifier onlyReactor() {
        if (msg.sender != address(reactor)) {
            revert MsgSenderNotReactor();
        }
        _;
    }

    constructor(address _whitelistedCaller, IReactor _reactor, address _clipper_exchange, address initialOwner) Ownable(initialOwner)
    {
        whitelistedCaller = _whitelistedCaller;
        reactor = _reactor;
        CLIPPER_EXCHANGE = _clipper_exchange;
    }

    /// @notice assume that we already have all output tokens
    function execute(SignedOrder calldata order, bytes calldata callbackData) external onlyWhitelistedCaller {
        reactor.executeWithCallback(order, callbackData);
    }

    /// @notice fill UniswapX orders using Clipper
    function reactorCallback(ResolvedOrder[] calldata resolvedOrders, bytes calldata callbackData) external onlyReactor {
        if (callbackData.length > 0) {
            ClipperSwapParams memory swapParams = abi.decode(
                callbackData,
                (ClipperSwapParams)
            );
            bytes32 s = swapParams.vs & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            uint8 v = 27 + uint8(uint256(swapParams.vs) >> 255);
            Signature memory theSignature = Signature(v,swapParams.r,s);
            delete v;
            delete s;
            if (address(resolvedOrders[0].input.token) == NATIVE) {
                IERC20(address(uint160(swapParams.packedOutput))).approve(address(reactor), type(uint256).max);
                ClipperCommonInterface(CLIPPER_EXCHANGE).sellEthForToken{value: (swapParams.packedInput >> 160) }(address(uint160(swapParams.packedOutput)),
                (swapParams.packedInput >> 160) , (swapParams.packedOutput >>160),
                swapParams.goodUntil, resolvedOrders[0].info.swapper, theSignature, "ClipperUniswapX");
            } else if (address(resolvedOrders[0].outputs[0].token) == NATIVE) {
                ClipperCommonInterface(CLIPPER_EXCHANGE).sellTokenForEth(address(uint160(swapParams.packedInput)),
                (swapParams.packedInput >> 160) , (swapParams.packedOutput >>160),
                swapParams.goodUntil, resolvedOrders[0].info.swapper, theSignature, "ClipperUniswapX");
                transferNative(address(reactor), address(this).balance);

            } else {
                IERC20(address(uint160(swapParams.packedOutput))).approve(address(reactor), type(uint256).max);
                ClipperCommonInterface(CLIPPER_EXCHANGE).swap(address(uint160(swapParams.packedInput)), address(uint160(swapParams.packedOutput)),
                 (swapParams.packedInput >> 160) , (swapParams.packedOutput >>160),
                 swapParams.goodUntil, resolvedOrders[0].info.swapper, theSignature, "ClipperUniswapX");
            }
        }
    }

    function rescueFunds(IERC20 token) external {
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function changeWhitelistedCaller(address newCaller) external onlyOwner {
        whitelistedCaller = newCaller;
    }

    function tokenEscapeAll() external {
        uint n = ClipperCommonInterface(CLIPPER_EXCHANGE).nTokens();
        for (uint i = 0; i < n; i++) {
            address token = ClipperCommonInterface(CLIPPER_EXCHANGE).tokenAt(i);
            uint256 toSend = IERC20(token).balanceOf(address(this));
            if(toSend > 1){
                toSend = toSend - 1;
            }
            IERC20(token).safeTransfer(owner(), toSend);
         }
    }

    function transferNative(address recipient, uint256 amount) internal {
        (bool success,) = recipient.call{value: amount, gas: TRANSFER_NATIVE_GAS_LIMIT}("");
        if (!success) revert NativeTransferFailed();
    }
}
