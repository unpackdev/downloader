// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IIDO.sol";

interface IIDOAllowance is IIDO {
    function initialize(IDOParams memory params) external override;

    function addAllowance(address _allowance) external;

    function removeAllowance(address _allowance) external;

    function deposit() external payable override;

    function claim() external override;

    function refund() external override;
}
