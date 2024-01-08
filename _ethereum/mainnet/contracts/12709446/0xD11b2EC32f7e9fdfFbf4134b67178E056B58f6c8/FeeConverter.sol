// SPDX-License-Identifier: MIT
// @author: https://github.com/SHA-2048

pragma solidity ^0.8.0;

import "./IWETH.sol";

import "./Controller.sol";
import "./Controllable.sol";
import "./AllowanceChecker.sol";
import "./ExternalMulticall.sol";

/**
 * FeeConverter is designed to receive any token accrued from
 * Metric Exchange fees. The ERC20 tokens can be converted into METRIC
 * and the caller will get an incentive as a % of the METRIC
 * balance generated. There is a function to trigger METRIC
 * distribution over eligible recipients. There is also
 * a wrapEth function, in case contract holds ETH.
 * All calls can be sequenced using the MultiCall
 * interface available on the contract
 *
 * All parameters can be changed on the Controller
 * contract: swapRouter, rewardToken, revenue recipients
 * as well as the fee conversion % incentive
 *
 * all action can be paused as well by the Controller.
 */
contract FeeConverter is ExternalMulticall, Controllable, AllowanceChecker {

    event FeeDistribution(
        address recipient,
        uint amount
    );

    constructor(Controller _controller) Controllable(_controller) {}

    receive() external payable {}

    function convertToken(
        address[] memory _path,
        uint _inputAmount,
        uint _minOutput,
        address _incentiveCollector
    ) external whenNotPaused {

        require(_path[_path.length - 1] == address(controller.rewardToken()), "Output token needs to be reward token");

        uint rewardTokenBalanceBeforeConversion = controller.rewardToken().balanceOf(address(this));
        _executeConversion(_path, _inputAmount, _minOutput);
        uint rewardTokenBalanceAfterConversion = controller.rewardToken().balanceOf(address(this));

        _sendIncentiveReward(
            _incentiveCollector,
            rewardTokenBalanceAfterConversion - rewardTokenBalanceBeforeConversion
        );
    }

    function wrapETH() external whenNotPaused {
        uint balance = address(this).balance;
        if (balance > 0) {
            IWETH(controller.swapRouter().weth()).deposit{value : balance}();
        }
    }

    function transferRewardTokenToReceivers() external whenNotPaused {

        Controller.RewardReceiver[] memory receivers = controller.getRewardReceivers();

        uint totalAmount = controller.rewardToken().balanceOf(address(this));
        uint remaining = totalAmount;
        uint nbReceivers = receivers.length;

        if (nbReceivers > 0) {
            for(uint i = 0; i < nbReceivers - 1; i++) {
                uint receiverShare = totalAmount * receivers[i].share / 100e18;
                _sendRewardToken(receivers[i].receiver, receiverShare);

                remaining -= receiverShare;
            }
            _sendRewardToken(receivers[nbReceivers - 1].receiver, remaining);
        }
    }

    function _executeConversion(
        address[] memory _path,
        uint _inputAmount,
        uint _minOutput
    ) internal {
        ISwapRouter router = controller.swapRouter();

        approveIfNeeded(_path[0], address(router));

        controller.swapRouter().swapExactTokensForTokens(
            _path,
            _inputAmount,
            _minOutput
        );
    }

    function _sendIncentiveReward(address _incentiveCollector, uint _totalAmount) internal {
        uint incentiveShare = controller.feeConversionIncentive();
        if (incentiveShare > 0) {
            uint callerIncentive = _totalAmount * incentiveShare / 100e18;
            _sendRewardToken(_incentiveCollector, callerIncentive);
        }
    }

    function _sendRewardToken(
        address _recipient,
        uint _amount
    ) internal {
        controller.rewardToken().transfer(_recipient, _amount);
        emit FeeDistribution(_recipient, _amount);
    }

}