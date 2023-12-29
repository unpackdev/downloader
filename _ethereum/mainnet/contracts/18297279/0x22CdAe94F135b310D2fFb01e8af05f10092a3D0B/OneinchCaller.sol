// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Address.sol";
import "./IAggregationRouterV5.sol";
import "./IUniswapV3Pool.sol";

/**
 * @title OneinchCaller contract
 * @author Cian
 * @notice The focal point of interacting with the 1inch protocol.
 * @dev This contract will be inherited by the strategy contract and the wrapper contract,
 * used for the necessary exchange between ETH (WETH) and stETH when necessary.
 * @dev When using this contract, it is necessary to first obtain the calldata through 1inch API.
 * The contract will then extract and verify the calldata before proceeding with the exchange.
 */
contract OneinchCaller {
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant W_ETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // 1inch v5 protocol is currently in use.
    address public constant oneInchRouter = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    uint256 private constant _UNIV3_ONE_FOR_ZERO_MASK = 1 << 255;

    /**
     * @dev Separate the function signature and detailed parameters in the calldata.
     * @param _swapData Calldata of 1inch.
     * @return functionSignature_ Function signature of the swap method.
     */
    function parseSwapCalldata(bytes memory _swapData)
        internal
        pure
        returns (bytes4 functionSignature_, bytes memory remainingBytes_)
    {
        // Extract function signature.(first 4 bytes of data)
        functionSignature_ = bytes4(_swapData[0]) | (bytes4(_swapData[1]) >> 8) | (bytes4(_swapData[2]) >> 16)
            | (bytes4(_swapData[3]) >> 24);

        uint256 remainingLength_ = _swapData.length - 4;
        // Create a variable to store the remaining bytes.
        remainingBytes_ = new bytes(remainingLength_);
        // IAggregationRouterV5.SwapDescription memory desc_;
        assembly {
            let src := add(_swapData, 0x24) // source data pointer (skip 4 bytes)
            let dst := add(remainingBytes_, 0x20) // destination data pointer
            let size := remainingLength_ // size to copy

            for {} gt(size, 31) {} {
                mstore(dst, mload(src))
                src := add(src, 0x20)
                dst := add(dst, 0x20)
                size := sub(size, 0x20)
            }
            let mask := sub(exp(2, mul(8, size)), 1)
            mstore(dst, and(mload(src), mask))
        }
        // (, desc_,,) =
        //     abi.decode(remainingBytes_, (IAggregationExecutor, IAggregationRouterV5.SwapDescription, bytes, bytes));
    }

    /**
     * @dev Executes the swap operation and verify the validity of the parameters and results.
     * @param _amount The maximum amount of currency spent.
     * @param _srcToken The token to be spent.
     * @param _dstToken The token to be received.
     * @param _swapData Calldata of 1inch.
     * @param _swapGetMin Minimum amount of the token to be received.
     * @return returnAmount_ Actual amount of the token spent.
     * @return spentAmount_ Actual amount of the token received.
     */
    function executeSwap(
        uint256 _amount,
        address _srcToken,
        address _dstToken,
        bytes memory _swapData,
        uint256 _swapGetMin
    ) internal returns (uint256 returnAmount_, uint256 spentAmount_) {
        (bytes4 functionSignature_, bytes memory remainingBytes_) = parseSwapCalldata(_swapData);
        if (functionSignature_ == IAggregationRouterV5.swap.selector) {
            (, IAggregationRouterV5.SwapDescription memory desc_,,) =
                abi.decode(remainingBytes_, (IAggregationExecutor, IAggregationRouterV5.SwapDescription, bytes, bytes));
            require(address(this) == desc_.dstReceiver, "1inch: Invalid receiver!");
            require(IERC20(_srcToken) == desc_.srcToken && IERC20(_dstToken) == desc_.dstToken, "1inch: Invalid token!");
            require(_amount >= desc_.amount, "1inch: Invalid input amount!");
            bytes memory returnData_;
            if (_srcToken == ETH_ADDR) {
                returnData_ = Address.functionCallWithValue(oneInchRouter, _swapData, _amount);
            } else {
                returnData_ = Address.functionCall(oneInchRouter, _swapData);
            }
            (returnAmount_, spentAmount_) = abi.decode(returnData_, (uint256, uint256));
            require(spentAmount_ <= desc_.amount, "1inch: unexpected spentAmount.");
            require(returnAmount_ >= _swapGetMin, "1inch: unexpected returnAmount.");
        } else if (functionSignature_ == IAggregationRouterV5.unoswap.selector) {
            (IERC20 srcTokenFromCalldata_, uint256 inputAmount_,,) =
                abi.decode(remainingBytes_, (IERC20, uint256, uint256, uint256[]));
            require(_amount >= inputAmount_, "1inch: Invalid input amount!");
            spentAmount_ = inputAmount_;
            uint256 dstTokenBefore_ =
                _dstToken == ETH_ADDR ? address(this).balance : IERC20(_dstToken).balanceOf(address(this));
            if (_srcToken == ETH_ADDR) {
                require(address(srcTokenFromCalldata_) == address(0), "1inch: Invalid token!");
                Address.functionCallWithValue(oneInchRouter, _swapData, _amount);
            } else {
                require(_srcToken == address(srcTokenFromCalldata_), "1inch: Invalid token!");
                Address.functionCall(oneInchRouter, _swapData);
            }
            returnAmount_ = _dstToken == ETH_ADDR
                ? (address(this).balance - dstTokenBefore_)
                : (IERC20(_dstToken).balanceOf(address(this)) - dstTokenBefore_);
            require(returnAmount_ > 0 && returnAmount_ >= _swapGetMin, "1inch: unexpected returnAmount.");
        } else if (functionSignature_ == IAggregationRouterV5.uniswapV3Swap.selector) {
            (uint256 inputAmount_,, uint256[] memory pools_) =
                abi.decode(remainingBytes_, (uint256, uint256, uint256[]));
            require(_amount >= inputAmount_, "1inch: Invalid input amount!");
            spentAmount_ = inputAmount_;
            address srcTokenFromCalldata_ = (pools_[0] & _UNIV3_ONE_FOR_ZERO_MASK == 0)
                ? IUniswapV3Pool(address(uint160(pools_[0]))).token0()
                : IUniswapV3Pool(address(uint160(pools_[0]))).token1();
            uint256 dstTokenBefore_ =
                _dstToken == ETH_ADDR ? address(this).balance : IERC20(_dstToken).balanceOf(address(this));
            if (_srcToken == ETH_ADDR) {
                require(srcTokenFromCalldata_ == W_ETH_ADDR, "1inch: Invalid token!");
                Address.functionCallWithValue(oneInchRouter, _swapData, _amount);
            } else {
                require(_srcToken == srcTokenFromCalldata_, "1inch: Invalid token!");
                Address.functionCall(oneInchRouter, _swapData);
            }
            returnAmount_ = _dstToken == ETH_ADDR
                ? (address(this).balance - dstTokenBefore_)
                : (IERC20(_dstToken).balanceOf(address(this)) - dstTokenBefore_);
            require(returnAmount_ > 0 && returnAmount_ >= _swapGetMin, "1inch: unexpected returnAmount.");
        } else {
            revert("1inch: Invalid function signature!");
        }
    }
}
