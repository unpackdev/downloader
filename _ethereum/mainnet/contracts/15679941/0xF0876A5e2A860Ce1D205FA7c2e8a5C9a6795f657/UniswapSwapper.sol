// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "./Initializable.sol";
import "./IPeripheryImmutableState.sol";
import "./IV3SwapRouter.sol";
import "./Denominations.sol";

import "./BytesLib.sol";
import "./Constant.sol";

contract UniswapSwapper is Initializable {
    using BytesLib for bytes;

    address public constant RECIPIENT_EXECUTEE = address(1);
    address public constant RECIPIENT_UNISWAP_ROUTER = address(2);

    enum MulticallResultAttribute { EMPTY, AMOUNT_IN, AMOUNT_OUT }

    struct MulticallData {
        address recipient;
        address tokenIn;
        address tokenOut; 
        uint256 amountIn; 
        uint256 amountOut; 
        MulticallResultAttribute resultType;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
      _disableInitializers();
    }
    
    function WETH9() public pure returns (address) {
        return Constant.WETH_ADDRESS;
    }

    function decodeWETH9Call(bytes memory data, uint256 value) external pure returns(address tokenIn, address tokenOut, uint256 amount) {
        bytes4 funcSig = data.toBytes4(0);
        if (funcSig == bytes4(keccak256("deposit()"))) {
            return (Denominations.ETH, WETH9(), value);
        } else if (funcSig == bytes4(keccak256("withdraw(uint256)"))) {
            return (WETH9(), Denominations.ETH, abi.decode(data.slice(4, data.length - 4), (uint256)));
        }

        revert("Failed to decode Uniswap bytecode");
    }

    function decodeUniswapMulticall(bytes memory rawData, uint256 value, bytes memory response) external view returns(MulticallData[] memory multicalData) {
        bytes[] memory executions = _decodeMulticall(rawData);
        bytes[] memory executionResults;
        uint256 remainEth = value;

        multicalData = new MulticallData[](executions.length);

        if (response.length != 0) {
            executionResults = abi.decode(response, (bytes[]));
        } 

        for (uint i = 0; i < executions.length; i++) {
            (bool success, bytes memory rawSwapData) = address(this).staticcall(executions[i]);
            require(success, "fail to decode uniswap multicall");

            MulticallData memory swapData = abi.decode(rawSwapData, (MulticallData));
            
            if (swapData.tokenIn == WETH9() && remainEth != 0) {
                require(swapData.amountIn <= remainEth, "fail to decode WETH swap data");
                swapData.tokenIn = Denominations.ETH;
                remainEth -= swapData.amountIn;
            }
            if (executionResults.length != 0) {
                if (swapData.resultType == MulticallResultAttribute.AMOUNT_IN) {
                    swapData.amountIn = abi.decode(executionResults[i], (uint256));
                } else if (swapData.resultType == MulticallResultAttribute.AMOUNT_OUT) {
                    swapData.amountOut = abi.decode(executionResults[i], (uint256));
                }
            }
            multicalData[i] = swapData;
        }

        require(remainEth == 0, "passing too much ETH to uniswap");
    }

    function _decodeMulticall(bytes memory _data) internal pure returns (bytes[] memory executions) {
        bytes4 funcSig = _data.toBytes4(0);
        if (funcSig == bytes4(keccak256("multicall(uint256,bytes[])"))) {
            (, executions) = abi.decode(_data.slice(4, _data.length - 4), (uint256, bytes[]));
        } else if (funcSig == bytes4(keccak256("multicall(bytes32,bytes[])"))) {
            (, executions) = abi.decode(_data.slice(4, _data.length - 4), (bytes32, bytes[]));
        } else {
           revert("Failed to decode Uniswap multicall bytecode");
        }
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactOutputSingle(
        IV3SwapRouter.ExactOutputSingleParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: params.amountInMaximum,
            amountOut: params.amountOut,
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }
    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactInputSingle(
        IV3SwapRouter.ExactInputSingleParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountIn: params.amountIn,
            amountOut: params.amountOutMinimum,
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactOutput(
        IV3SwapRouter.ExactOutputParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.path.toAddress(0),
            tokenOut: params.path.toAddress(params.path.length - 20),
            amountIn: params.amountInMaximum,
            amountOut: params.amountOut, 
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V3SwapRouter.sol
    function exactInput(
        IV3SwapRouter.ExactInputParams calldata params
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: params.recipient,
            tokenIn: params.path.toAddress(0),
            tokenOut: params.path.toAddress(params.path.length - 20),
            amountIn: params.amountIn,
            amountOut: params.amountOutMinimum, 
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V2SwapRouter.sol
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: path[0],
            tokenOut: path[path.length - 1],
            amountIn: amountInMax,
            amountOut: amountOut, 
            resultType: MulticallResultAttribute.AMOUNT_IN
        });
    }

    // From Uniswap/swap-router-contracts/contracts/V2SwapRouter.sol
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: path[0],
            tokenOut: path[path.length - 1],
            amountIn: amountIn,
            amountOut: amountOutMin, 
            resultType: MulticallResultAttribute.AMOUNT_OUT
        });
    }

    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: address(0),
            tokenOut: Denominations.ETH,
            amountIn: 0,
            amountOut: amountMinimum, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function refundETH() external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: address(0),
            tokenIn: address(0),
            tokenOut: address(0),
            amountIn: 0,
            amountOut: 0,
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function selfPermit(
        address, uint256, uint256, uint8, bytes32, bytes32
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: address(0),
            tokenIn: address(0),
            tokenOut: address(0),
            amountIn: 0,
            amountOut: 0, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external pure returns (MulticallData memory) {
        return MulticallData({
            recipient: recipient,
            tokenIn: address(0),
            tokenOut: token,
            amountIn: 0,
            amountOut: amountMinimum, 
            resultType: MulticallResultAttribute.EMPTY
        });
    }

    uint256[50] private __gap;

}