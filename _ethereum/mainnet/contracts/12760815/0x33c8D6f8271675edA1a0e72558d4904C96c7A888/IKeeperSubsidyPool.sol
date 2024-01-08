// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;


interface IKeeperSubsidyPool {

    function getController() external view returns (address);

    function setController(address _controller) external returns (bool);

    function setBeneficiary(address beneficiary, bool canRequest) external returns (bool);

    function isBeneficiary(address beneficiary) external view returns (bool);

    function requestSubsidy(address token, uint256 amount) external returns (bool);
}
