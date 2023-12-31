// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./ICoreSwapV1.sol";
import "./DefinitiveAssets.sol";
import "./Context.sol";
import "./BubbleReverts.sol";
import "./DefinitiveConstants.sol";
import "./DefinitiveErrors.sol";

struct CoreSwapConfig {
    address[] swapTokens;
    address[] swapOutputTokens;
    address[] swapHandlers;
}

struct SwapPayload {
    address handler;
    uint256 amount; // set 0 for maximum available balance
    address swapToken;
    uint256 amountOutMin;
    bool isDelegate;
    bytes handlerCalldata;
    bytes signature;
}

abstract contract CoreSwap is ICoreSwapV1, Context {
    using DefinitiveAssets for IERC20;

    uint256 internal swapsThisBlock;
    uint256 internal latestBlockNumber;
    uint256 public immutable MAX_SWAPS_PER_BLOCK;

    /**
     * @notice Maintains mapping for reward tokens
     * @notice Tokens _not_ in this list will be treated as principal assets
     * @dev erc20 token => valid
     */
    mapping(address => bool) public _swapTokens;

    /// @dev erc20 token => valid
    mapping(address => bool) public _swapOutputTokens;

    /// @dev handler contract => enabled
    mapping(address => bool) public _swapHandlers;

    modifier enforceSwapLimit(SwapPayload[] memory payloads) {
        if (block.number != latestBlockNumber) {
            latestBlockNumber = block.number;
            delete swapsThisBlock;
        }
        swapsThisBlock += payloads.length;
        if (swapsThisBlock > MAX_SWAPS_PER_BLOCK) {
            revert SwapLimitExceeded();
        }
        _;
    }

    constructor(CoreSwapConfig memory coreSwapConfig) {
        uint256 coreswapConfigSwapTokensLength = coreSwapConfig.swapTokens.length;
        MAX_SWAPS_PER_BLOCK = DefinitiveConstants.MAX_SWAPS_PER_BLOCK;
        for (uint256 i; i < coreswapConfigSwapTokensLength; ) {
            _swapTokens[coreSwapConfig.swapTokens[i]] = true;
            unchecked {
                ++i;
            }
        }
        uint256 coreSwapConfigSwapOutputTokensLength = coreSwapConfig.swapOutputTokens.length;
        for (uint256 i; i < coreSwapConfigSwapOutputTokensLength; ) {
            _swapOutputTokens[coreSwapConfig.swapOutputTokens[i]] = true;
            unchecked {
                ++i;
            }
        }
        uint256 coreSwapConfigSwapHandlersLength = coreSwapConfig.swapHandlers.length;
        for (uint256 i; i < coreSwapConfigSwapHandlersLength; ) {
            _swapHandlers[coreSwapConfig.swapHandlers[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function enableSwapTokens(address[] memory swapTokens) public virtual;

    function disableSwapTokens(address[] memory swapTokens) public virtual;

    function _updateSwapTokens(address[] memory swapTokens, bool enabled) internal {
        uint256 swapTokensLength = swapTokens.length;
        for (uint256 i; i < swapTokensLength; ) {
            _swapTokens[swapTokens[i]] = enabled;
            emit SwapTokenUpdate(_msgSender(), swapTokens[i], enabled);
            unchecked {
                ++i;
            }
        }
    }

    function enableSwapOutputTokens(address[] memory swapOutputTokens) public virtual;

    function disableSwapOutputTokens(address[] memory swapOutputTokens) public virtual;

    function _updateSwapOutputTokens(address[] memory swapOutputTokens, bool enabled) internal {
        uint256 swapOutputTokensLength = swapOutputTokens.length;
        for (uint256 i; i < swapOutputTokensLength; ) {
            _swapOutputTokens[swapOutputTokens[i]] = enabled;
            emit SwapOutputTokenUpdate(_msgSender(), swapOutputTokens[i], enabled);
            unchecked {
                ++i;
            }
        }
    }

    function enableSwapHandlers(address[] memory swapHandlers) public virtual;

    function disableSwapHandlers(address[] memory swapHandlers) public virtual;

    function _updateSwapHandlers(address[] memory swapHandlers, bool enabled) internal {
        uint256 swapHandlersLength = swapHandlers.length;
        for (uint256 i; i < swapHandlersLength; ) {
            _swapHandlers[swapHandlers[i]] = enabled;
            emit SwapHandlerUpdate(_msgSender(), swapHandlers[i], enabled);
            unchecked {
                ++i;
            }
        }
    }

    function swap(
        SwapPayload[] memory payloads,
        address outputToken,
        uint256 amountOutMin,
        uint256 feePct
    ) external virtual returns (uint256 outputAmount);

    function _swap(
        SwapPayload[] memory payloads,
        address expectedOutputToken
    ) internal enforceSwapLimit(payloads) returns (uint256[] memory inputTokenAmounts, uint256 outputTokenAmount) {
        if (!_swapOutputTokens[expectedOutputToken]) {
            revert InvalidSwapOutputToken();
        }
        uint256 payloadsLength = payloads.length;
        inputTokenAmounts = new uint256[](payloadsLength);
        uint256 outputTokenBalanceStart = DefinitiveAssets.getBalance(expectedOutputToken);

        for (uint256 i; i < payloadsLength; ) {
            SwapPayload memory payload = payloads[i];

            if (!_swapHandlers[payload.handler]) {
                revert InvalidSwapHandler();
            }

            if (expectedOutputToken == payload.swapToken) {
                revert SwapTokenIsOutputToken();
            }

            uint256 outputTokenBalanceBefore = DefinitiveAssets.getBalance(expectedOutputToken);
            inputTokenAmounts[i] = DefinitiveAssets.getBalance(payload.swapToken);

            (uint256 _outputAmount, address _outputToken) = _processSwap(payload, expectedOutputToken);

            if (_outputToken != expectedOutputToken) {
                revert InvalidOutputToken();
            }
            if (_outputAmount < payload.amountOutMin) {
                revert InvalidReportedOutputAmount();
            }
            uint256 outputTokenBalanceAfter = DefinitiveAssets.getBalance(expectedOutputToken);

            if ((outputTokenBalanceAfter - outputTokenBalanceBefore) < payload.amountOutMin) {
                revert InvalidExecutedOutputAmount();
            }

            // Update `inputTokenAmounts` to reflect the amount of tokens actually swapped
            inputTokenAmounts[i] -= DefinitiveAssets.getBalance(payload.swapToken);
            unchecked {
                ++i;
            }
        }

        outputTokenAmount = DefinitiveAssets.getBalance(expectedOutputToken) - outputTokenBalanceStart;
    }

    function _processSwap(SwapPayload memory payload, address expectedOutputToken) private returns (uint256, address) {
        // Override payload.amount with validated amount
        payload.amount = _getValidatedPayloadAmount(payload);

        /// @dev if asset is in _swapTokens, then it is a reward token
        bool isPrincipalAssetSwap = !_swapTokens[payload.swapToken];

        bytes memory _calldata = _getEncodedSwapHandlerCalldata(
            payload,
            expectedOutputToken,
            isPrincipalAssetSwap,
            payload.isDelegate
        );

        bool _success;
        bytes memory _returnBytes;
        if (payload.isDelegate) {
            // slither-disable-next-line controlled-delegatecall
            (_success, _returnBytes) = payload.handler.delegatecall(_calldata);
        } else {
            _prepareAssetsForNonDelegateHandlerCall(payload, payload.amount);
            (_success, _returnBytes) = payload.handler.call(_calldata);
        }

        if (!_success) {
            CallUtils.revertFromReturnedData(_returnBytes);
        }

        return abi.decode(_returnBytes, (uint256, address));
    }

    function _getEncodedSwapHandlerCalldata(
        SwapPayload memory payload,
        address expectedOutputToken,
        bool isPrincipalAssetSwap,
        bool isDelegateCall
    ) internal pure virtual returns (bytes memory);

    function _getValidatedPayloadAmount(SwapPayload memory payload) private view returns (uint256 amount) {
        uint256 balance = DefinitiveAssets.getBalance(payload.swapToken);

        // Ensure balance > 0
        DefinitiveAssets.validateAmount(balance);

        amount = payload.amount;

        if (amount != 0 && balance < amount) {
            revert InsufficientSwapTokenBalance();
        }

        // maximum available balance if amount == 0
        if (amount == 0) {
            return balance;
        }
    }

    function _prepareAssetsForNonDelegateHandlerCall(SwapPayload memory payload, uint256 amount) private {
        if (payload.swapToken == DefinitiveConstants.NATIVE_ASSET_ADDRESS) {
            // Send ETH to handler
            DefinitiveAssets.safeTransferETH(payable(payload.handler), amount);
        } else {
            IERC20(payload.swapToken).resetAndSafeIncreaseAllowance(address(this), payload.handler, amount);
        }
    }
}
