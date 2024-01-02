// SPDX-License-Identifier: ISC

pragma solidity 0.7.5;
pragma abicoder v2;
import "./Utils.sol";

interface IWombatRouter {
    function swap(
        address _fromToken,
        address _toToken,
        uint256 _fromAmount,
        uint256 _minimumToAmount,
        address _to,
        uint256 _deadline
    ) external returns (uint256 amountOut);
}
