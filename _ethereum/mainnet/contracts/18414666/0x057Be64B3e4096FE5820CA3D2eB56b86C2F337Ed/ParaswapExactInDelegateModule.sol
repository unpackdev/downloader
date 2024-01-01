// SPDX-License-Identifier: UNLICENSED

import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ExactInputDelegateSwapModule.sol";
import "./IWETH9.sol";
import "./IParaSwapAugustusRegistry.sol";
import "./IParaSwapAugustus.sol";

pragma solidity ^0.8.21;

contract ParaswapExactInDelegateModule is ExactInputDelegateSwapModule {
    using SafeERC20 for IERC20;

    error InvalidNativeSwap();
    error InvalidSwapTarget();
    error InsufficientInputBalance();
    error InvalidSwapBalance();
    error InvalidSwapOutput();

    IWETH9 public immutable weth;
    IParaSwapAugustusRegistry public immutable registry;

    constructor(IParaSwapAugustusRegistry _registry, IWETH9 _weth) {
        require(!_registry.isValidAugustus(address(0)), "Not a valid router address");
        registry = _registry;
        weth = _weth;
    }

    /**
     * Decode the swap data that will be passed to the swap router
     * @param swapData the bytes swap data to be decoded
     * @return inputTokenAddress the address of the input token to be swapped
     * @return outputTokenAddress the address of the output token
     * @return wethAddress the address of wrapped ether contract
     */
    function decodeSwapData(bytes calldata swapData) external view override returns (address, address, address) {
        return _decodeSwapData(swapData);
    }

    /**
     * @notice performs an exact input swap using native ETH
     * @param swapParams the parameters required to make the swap (See: ExactInputDelegateSwapModule.ExactInputParams)
     * @return outputTokenReceived the amount of the token received by the swap
     */
    function exactInputNativeSwap(bytes calldata swapParams) external override returns (uint256) {
        ExactInputParams memory params = abi.decode(swapParams, (ExactInputParams));

        weth.deposit{ value: params.inputTokenAmount }();

        (address inputTokenAddress, uint256 outputTokenReceived) = _exactInputSwap(params);

        if (address(inputTokenAddress) != address(weth)) revert InvalidNativeSwap();

        return outputTokenReceived;
    }

    /**
     * @notice performs an exact output swap using an ERC-20 token and refunds leftover tokens to the user
     * @param swapParams the parameters required to make the swap (See: ExactInputDelegateSwapModule.ExactInputParams)
     * @return outputTokenReceived the amount of the token received by the swap
     */
    function exactInputSwap(bytes calldata swapParams) external override returns (uint256 outputTokenReceived) {
        ExactInputParams memory params = abi.decode(swapParams, (ExactInputParams));
        (, outputTokenReceived) = _exactInputSwap(params);
    }

    /**
     * @notice private method to perform an exact input swap on the augustus router
     * @param swapParams the parameters required to make the swap (See: ExactInputDelegateSwapModule.ExactInputParams)
     * @return inputTokenAddress the address of the token being swapped
     * @return outputTokenReceived the amount of the token received by the swap
     */
    function _exactInputSwap(ExactInputParams memory swapParams) private returns (address, uint256) {
        (bytes memory paraswapCalldata, address augustus, IERC20 inputToken, IERC20 outputToken) = abi.decode(
            swapParams.swapData,
            (bytes, address, IERC20, IERC20)
        );

        if (!registry.isValidAugustus(augustus)) revert InvalidSwapTarget();

        uint256 balanceBeforeOutputToken = outputToken.balanceOf(address(this));

        _swap(augustus, inputToken, swapParams.inputTokenAmount, paraswapCalldata);

        uint256 outputTokenBalance = outputToken.balanceOf(address(this));
        uint256 outputTokenReceived = outputTokenBalance - balanceBeforeOutputToken;
        if (outputTokenReceived < swapParams.paymentTokenAmountMin) revert InvalidSwapOutput();

        return (address(inputToken), outputTokenReceived);
    }

    function _swap(address augustus, IERC20 inputToken, uint256 inputTokenAmount, bytes memory data) internal {
        address tokenTransferProxy = IParaSwapAugustus(augustus).getTokenTransferProxy();

        uint256 allowance = inputToken.allowance(address(this), tokenTransferProxy);

        if (allowance == 0) {
            inputToken.safeApprove(tokenTransferProxy, inputTokenAmount);
        } else if (allowance < inputTokenAmount) {
            inputToken.safeApprove(tokenTransferProxy, 0);
            inputToken.safeApprove(tokenTransferProxy, inputTokenAmount);
        }

        (bool success, ) = address(augustus).call(data);
        if (!success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    /**
     * @notice decode the input token and output token from the swapData input
     * @param swapData the external calldata required for the swap
     * @return inputTokenAddress the address of the token being swapped
     * @return outputTokenAddress the address of the token being swapped to
     * @return wethAddress the address of wrapped ether contract
     */
    function _decodeSwapData(bytes calldata swapData) private view returns (address, address, address) {
        (, , address inputTokenAddress, address outputTokenAddress) = abi.decode(
            swapData,
            (bytes, address, address, address)
        );

        return (inputTokenAddress, outputTokenAddress, address(weth));
    }

    receive() external payable {}
}
