// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./Enums.sol";
import "./Errors.sol";
import "./IWETH9.sol";
import "./IInverseBondingCurve.sol";

contract InverseBondingCurveRouter {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    IWETH9 private _weth;

    constructor(address wethAddress) {
        _weth = IWETH9(wethAddress);
    }

    /**
     * @notice  Execute curve function with wrap/unwrap
     * @dev     
     * @param   recipient : Recipient to receive token
     * @param   curve : Curve contract to execute function
     * @param   useNative : Whether using native token(ETH)
     * @param   command : Action command to execute
     * @param   data : Call data of the function call
     */
    function execute(address recipient, address curve, bool useNative, CommandType command, bytes memory data) external payable {
        IInverseBondingCurve curveContract = IInverseBondingCurve(curve);
        IERC20 reserveToken = IERC20(curveContract.reserveTokenAddress());
        IERC20 inverseToken = IERC20(curveContract.inverseTokenAddress());
        // Send back ether if not using ETH for input token
        if (msg.value > 0) {
            if (useNative && address(reserveToken) == address(_weth)) {
                _weth.deposit{value: msg.value}();
                IERC20(_weth).safeTransfer(curve, msg.value);
            } else {
                revert EtherNotAccept();
            }
        }

        uint256 reserveBalanceBefore = reserveToken.balanceOf(address(this));
        uint256 inverseBalanceBefore = inverseToken.balanceOf(address(this));
        _payAndExecute(recipient, curve, useNative, command, reserveToken, inverseToken, data);
        uint256 reserveBalanceAfter = reserveToken.balanceOf(address(this));
        uint256 inverseBalanceAfter = inverseToken.balanceOf(address(this));

        if (inverseBalanceAfter > inverseBalanceBefore) {
            inverseToken.safeTransfer(recipient, inverseBalanceAfter - inverseBalanceBefore);
        }

        if (reserveBalanceAfter > reserveBalanceBefore) {
            uint256 amountToUser = reserveBalanceAfter - reserveBalanceBefore;
            if (useNative && address(reserveToken) == address(_weth)) {
                _weth.withdraw(amountToUser);
                payable(recipient).sendValue(amountToUser);
            } else {
                reserveToken.safeTransfer(recipient, amountToUser);
            }
        }
    }

    /**
     * @notice  Pay curve contract and execute action
     * @dev     
     * @param   recipient : Recipient to receive token
     * @param   curve : Curve contract to execute function
     * @param   useNative : Whether using native token(ETH)
     * @param   command : Action command to execute
     * @param   reserveToken : Reserve token contract address
     * @param   inverseToken : Inverse token contract address
     * @param   data : Call data of the function call
     */
    function _payAndExecute(
        address recipient,
        address curve,
        bool useNative,
        CommandType command,
        IERC20 reserveToken,
        IERC20 inverseToken,
        bytes memory data
    ) private {
        (uint256 reserveTokenAmount, uint256 inverseTokenAmount, bytes memory curveCallData) = _getInputAndCallData(command, data);

        if (reserveTokenAmount > 0) {
            if (!useNative) {
                reserveToken.safeTransferFrom(recipient, curve, reserveTokenAmount);
            }
        }
        if (inverseTokenAmount > 0) {
            inverseToken.safeTransferFrom(recipient, curve, inverseTokenAmount);
        }

        curve.functionCall(curveCallData);
    }

    /**
     * @notice  Get token input amount and calldata to curve contract
     * @dev     
     * @param   command : Action command to execute
     * @param   data : Function call data parameters
     * @return  reserveTokenAmount : Reserve token amount need to transfer to curve contract
     * @return  inverseTokenAmount : Inverse token amount need to transfer to curve contract
     * @return  curveCallData : Call data of the function call
     */
    function _getInputAndCallData(CommandType command, bytes memory data)
        private
        view
        returns (uint256 reserveTokenAmount, uint256 inverseTokenAmount, bytes memory curveCallData)
    {
        if (command == CommandType.ADD_LIQUIDITY) {
            (address recipient, uint256 reserveIn, uint256[2] memory priceLimits) =
                abi.decode(data, (address, uint256, uint256[2]));
            reserveTokenAmount = reserveIn;
            curveCallData = abi.encodeWithSignature("addLiquidity(address,uint256,uint256[2])", recipient, reserveIn, priceLimits);
        } else if (command == CommandType.REMOVE_LIQUIDITY) {
            (, uint256 inverseTokenIn, uint256[2] memory priceLimits) = abi.decode(data, (address, uint256, uint256[2]));
            inverseTokenAmount = inverseTokenIn;
            curveCallData =
                abi.encodeWithSignature("removeLiquidity(address,uint256,uint256[2])", msg.sender, inverseTokenIn, priceLimits);
        } else if (command == CommandType.BUY_TOKEN) {
            (, uint256 reserveIn, uint256 exactAmountOut, uint256[2] memory priceLimits, uint256[2] memory reserveLimits) =
                abi.decode(data, (address, uint256, uint256, uint256[2], uint256[2]));
            reserveTokenAmount = reserveIn;
            curveCallData = abi.encodeWithSignature("buyTokens(address,uint256,uint256,uint256[2],uint256[2])",
                msg.sender, reserveIn, exactAmountOut, priceLimits, reserveLimits);
        } else if (command == CommandType.SELL_TOKEN) {
            (, uint256 inverseTokenIn, uint256[2] memory priceLimits, uint256[2] memory reserveLimits) =
                abi.decode(data, (address, uint256, uint256[2], uint256[2]));
            inverseTokenAmount = inverseTokenIn;
            curveCallData = abi.encodeWithSignature(
                "sellTokens(address,uint256,uint256[2],uint256[2])", msg.sender, inverseTokenIn, priceLimits, reserveLimits
            );
        } else if (command == CommandType.CLAIM_REWARD) {
            curveCallData = abi.encodeWithSignature("claimReward(address)", msg.sender);
        } else if (command == CommandType.STAKE) {
            (, uint256 amount) = abi.decode(data, (address, uint256));
            inverseTokenAmount = amount;
            curveCallData = abi.encodeWithSignature("stake(address,uint256)", msg.sender, amount);
        } else if (command == CommandType.UNSTAKE) {
            (, uint256 amount) = abi.decode(data, (address, uint256));
            curveCallData = abi.encodeWithSignature("unstake(address,uint256)", msg.sender, amount);
        } else {
            revert CommandUnsupport();
        }
    }

    receive() external payable {
        if(msg.sender != address(_weth)){
            revert DepositNotAllowed();
        }
    }
}
