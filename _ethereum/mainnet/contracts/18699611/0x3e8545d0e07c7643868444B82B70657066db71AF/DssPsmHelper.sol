// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

import "./DssPsm.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @title DssPsmHelper
 * @notice Helper that allows to use dai amount to buy gem
 */
abstract contract DssPsmHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant private WAD = 1e18;
    uint256 constant private TO18CONVERSION_FACTOR = 1000000000000;

    function buyGemInverted(
        uint256 amountSpecified,
        DssPsm dssPsm,
        address recipient
    ) external view returns (address target, address sourceTokenInteractionTarget, uint256 actualSwapAmount, bytes memory data) {
        uint256 tout = dssPsm.tout();
        uint256 gemAmt = amountSpecified / TO18CONVERSION_FACTOR;
        if (tout > 0) {
            gemAmt = (amountSpecified * WAD)/(WAD + tout);
        }
        bytes memory resultData = abi.encodeCall(dssPsm.buyGem, (recipient, gemAmt));
        // Value is 0 because DssPsm is not payable
        return (address(dssPsm), address(dssPsm), amountSpecified, resultData);
    }
}
