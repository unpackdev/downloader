// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdapterBase.sol";

/**
// @title Adapter Contract for Kyberswap DEX Aggregator.
// @notice Follows AdapterBase interface.
*/
contract KyberswapAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public kyberswapRouter;

    constructor(address _dispatcher, address _kyberswapRouter) AdapterBase(_dispatcher) {
        kyberswapRouter = _kyberswapRouter;
    }

    function setKyberswapRouter(address _kyberswapRouter) public onlyDispatcher {
        require(_kyberswapRouter != address(0), "ZERO_ADDRESS_FORBIDDEN");
        kyberswapRouter = _kyberswapRouter;
    }

    /**
    // @dev Generic function to call 0x swap function
    // @param _fromToken input token address
    // @param _fromAmount input token amount
    // @param _toToken output token address
    // @param _swapCallData swap callData (intended for 1inch router)
    // @notice funds must be transferred to this contract before calling this function
    // @dev see NATIVE constant from AdapterBase for specifying native token as input or output
    */
    function callAction(
        address /*_fromUser*/,
        address _fromToken,
        uint256 _fromAmount,
        address _toToken,
        bytes memory _swapCallData
    ) public payable override onlyDispatcher returns (uint256 returnAmount) {
        require(_fromToken != address(0) && _toToken != address(0), "INVALID_ASSET_ADDRESS");
        bool success;
        bytes memory result;

        if (_fromToken != NATIVE) {
            require(IERC20(_fromToken).balanceOf(address(this)) >= _fromAmount, "UNAVAILABLE_FUNDS");
            IERC20(_fromToken).safeIncreaseAllowance(kyberswapRouter, _fromAmount);
            // solhint-disable-next-line
            (success, result) = kyberswapRouter.call(_swapCallData);
            IERC20(_fromToken).safeApprove(kyberswapRouter, 0);
        } else {
            require(msg.value >= _fromAmount, "VALUE_TOO_LOW");
            // solhint-disable-next-line
            (success, result) = kyberswapRouter.call{value: _fromAmount}(_swapCallData);
        }
        require(success, "KYBERSWAP_SWAP_FAIL");

        (returnAmount, ) = abi.decode(result, (uint256, uint256));
    }
}
