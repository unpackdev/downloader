// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFeeManager {
    //********************EVENT*******************************//
    event Withdrawal(address payment, address account, uint256 amount);
    event ApproveAdded(address payment, address account, uint256 amount);
    event ApproveReduced(address payment, address account, uint256 amount);

    //********************FUNCTION*******************************//

    /// @dev pay the baseFee
    /// @notice the msg.value should be equal to baseFee
    function payBaseFee() external payable;

    /// @dev approve payment to spender.
    /// @notice  only allowed by owner.
    function addApprove(address payment, address spender, uint256 amount) external;

    /// @notice  only allowed by owner.
    function reduceApprove(address payment, address spender, uint256 amount) external;

    /// @dev set base fee of create a game, the payment is eth
    /// @notice only owner
    function setBaseFee(uint256 amount) external;

    /// @dev set factory to calc fee
    /// @notice only owner, factor<=100
    function setFactor(uint256 factor) external;

    /// @dev withdraw if have enough allowance
    function withdraw(address payment, uint256 amount) external;

    /// @dev calc fee
    function calcFee(uint256 amount) external view returns (uint256);

    function baseFee() external view returns (uint256);

    function getFactor() external view returns (uint256);

    function allowance(address payment, address spender) external view returns (uint256);

    function totalBaseFee() external view returns (uint256);
}
