// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IValidatorRegistry
/// @notice Node validator registry interface
interface IValidatorRegistry {
    function addValidator(uint256 _validatorId) external;

    function removeValidator(uint256 _validatorId) external;

    function setPreferredDepositValidatorId(uint256 _validatorId) external;

    function setPreferredWithdrawalValidatorId(uint256 _validatorId) external;

    function togglePause() external;

    function preferredDepositValidatorId() external view returns (uint256);

    function preferredWithdrawalValidatorId() external view returns (uint256);

    function validatorIdExists(uint256 _validatorId)
        external
        view
        returns (bool);

    function getStakeManager() external view returns (address _stakeManager);

    function getValidatorId(uint256 _index) external view returns (uint256);

    function getValidators() external view returns (uint256[] memory);

    event AddValidator(uint256 indexed _validatorId);
    event RemoveValidator(uint256 indexed _validatorId);
    event SetPreferredDepositValidatorId(uint256 indexed _validatorId);
    event SetPreferredWithdrawalValidatorId(uint256 indexed _validatorId);
}
