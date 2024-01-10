// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IStrategyPool.sol";

import "./IDummyToken.sol";

/**
 * @title Dummy pool
 */
contract StrategyDummy is IStrategyPool, Ownable {
    using SafeERC20 for IERC20;

    address public broker;
    modifier onlyBroker() {
        require(msg.sender == broker, "caller is not broker");
        _;
    }

    event BrokerUpdated(address broker);
    event OutputTokensUpdated(address wrapToken, bool enabled);

    mapping(address => bool) public supportedOutputTokens;

    constructor(
        address _broker
    ) {
        broker = _broker;
    }

    function sellErc(address inputToken, address outputToken, uint256 inputAmt) external onlyBroker returns (uint256 outputAmt) {
        bool toBuy = supportedOutputTokens[outputToken];
        bool toSell = supportedOutputTokens[inputToken];

        require(toBuy || toSell, "not supported tokens!");

        IERC20(inputToken).safeTransferFrom(msg.sender, address(this), inputAmt);
        if (toBuy) {
            IERC20(inputToken).safeIncreaseAllowance(outputToken, inputAmt);
            IDummyToken(outputToken).buy(inputAmt);
            outputAmt = IERC20(outputToken).balanceOf(address(this));
            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        } else {
            IDummyToken(inputToken).sell(inputAmt);
            outputAmt = IERC20(outputToken).balanceOf(address(this));
            IERC20(outputToken).safeTransfer(msg.sender, outputAmt);
        }
    }

    function sellEth(address outputToken) external onlyBroker payable returns (uint256 outputAmt) {
        // do nothing
    }

    function updateBroker(address _broker) external onlyOwner {
        broker = _broker;
        emit BrokerUpdated(broker);
    }

    function setSupportedOutputToken(address _outputToken, bool _enabled) external onlyOwner {
        supportedOutputTokens[_outputToken] = _enabled;
        emit OutputTokensUpdated(_outputToken, _enabled);
    }
}
