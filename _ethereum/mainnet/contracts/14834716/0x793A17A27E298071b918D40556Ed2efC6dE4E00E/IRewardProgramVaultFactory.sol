//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IRewardProgramVaultFactory {

    event CreatedRewardProgramVault(address contractAddress, string name);

    /// ###### only admin ######

    /// @dev set Staker
    /// @param _staker staker address
    function setStaker(
        address _staker
    ) external;


    /// @dev set waitStartSeconds
    /// @param _waitStartSeconds waitStartSeconds
    function setWaitStartSeconds(
        uint256 _waitStartSeconds
    ) external;


    /// ### anybody can use

    /// @dev Create a RewardProgramVaultProxy
    /// @param _name name
    /// @param pool pool address
    /// @param rewardToken  rewardToken address
    /// @param _admin  admin address
    /// @return created contract address
    function create(
        string calldata _name,
        address pool,
        address rewardToken,
        address _admin
    )
        external
        returns (address);
}
