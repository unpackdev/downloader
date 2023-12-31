// SPDX-License-Identifier: GPL-3.0

/*
//   ::::::::::::::::::::+***+==:.                                    
//   ::::::::::::::::::::+************+-                              
//   ::::::::::::::::::::+****************+.                          
//   ::::::::::::::::::::+******************-                         
//   ::::::::::::::::::::+********************:                       
//   ::::::::::::::::::::+*********************-                      
//   ::::::::::::::::::::+*********************+                      
//   ....................=++++++++++++++++++++++                      
//                       -======================                      
//                       -=====================                       
//                       -===================-                        
//                       -=================.                          
//                       -=============:                              
//                       -=====-::.                                   
//                       ....
*/

pragma solidity ^0.8.9;

import "./IApplication.sol";
import "./IStaking.sol";

/// @title  DELIGHT T staking pool contract interface
/// @author Bryan RHEE <bryan@delightlabs.io>
/// @notice In the past, a staking provider was a singular account bonded with an operator account,
///          necessitating each participant to individually maintain their nodes.
///         However, a staking provider evolves into a dynamic contract from multiple stakers.
/// @dev    Owner-only methods are not revealed in the interface.
///         Please check contracts/README.md first for breif understanding
///         If you need to check it, please check StakingPool.sol
/// @custom:experimental This contract is not tested on the production environment
interface ITStakingPool {
    /// @notice Increases the amount of the stake for the given staking provider.
    ///         Please call approve() of T token with this contract address as a spender
    ///          before executing this method
    /// @dev    Transfer T token from the user's account to this pool contract
    ///         approve() call is needed in advance
    ///
    /// @param  _amount the amount of T token that the staker want to stake
    function requestStake(uint96 _amount) external;

    /// @notice If a user requested staking but it is not activated yet, it can be withdrawable.
    /// @dev    The pool contract receives staking request within a month
    ///          and it applies the end of every month
    ///         The stakers can withdraw their deposit within this time window
    ///
    /// @param  _amount the amount of T token that the staker want to withdraw
    function withdrawFromDeposit(uint96 _amount) external;

    /// @notice Users can request unstaking by this method
    ///         Be sure that this unstaking request is not activated immediately
    /// @dev    When a user executes this method, put the request into the unstaking queue.
    ///         And activates(increasing authorization) it in the end of the month
    /// @param _amount the amount of T token that the staker want to request unstaking
    function requestUnstake(uint96 _amount) external;

    /// @notice Users can claim the reward & unstaked tokens by this method
    function claim() external;

    //
    //
    // View functions
    //
    //

    /// @notice Check the setting of operator address of the given application
    /// @dev    Not using from the variable of this contract,
    ///          but directly querying the view function of the given application
    /// @param _application address of the application
    /// @return address operator address of the given application
    function getOperatorFromApplication(
        IApplication _application
    ) external view returns (address);

    /// @notice Returns the authorized stake amount of the staking provider for
    ///         the application.
    /// @dev    Not using from the variable of this contract,
    ///          but directly querying the view function of the given application
    /// @param _application address of the application
    /// @return uint96 the amount of the staked T token of the given application
    function authorizedTBTCStake(
        IApplication _application
    ) external view returns (uint96);

    /// @notice Returns the amount of T staked from the snapshot of the given period
    /// @param  _period  the unique number of the staking period, which is increased by each month
    /// @param  _staker  the address of the staking provider
    /// @return bool    shows whether this contract claims the reward of the month
    ///                  and distributes to each stakers
    /// @return uint96  shows how much the user stakes in the given period
    function stakedAmountByGivenPeriod(
        uint16 _period,
        address _staker
    ) external view returns (bool, uint96);

    /// @notice Returns the amount of T staked right now
    /// @param  _staker  the address of the staking provider
    /// @return uint96  shows how much the user stakes right now
    function currStakingAmount(address _staker) external view returns (uint96);

    /// @notice Returns the amount of T deposited right now
    /// @param  _staker  the address of the staking provider
    /// @return uint96  shows how much the user deposits right now
    function currDepositedAmount(
        address _staker
    ) external view returns (uint96);

    /// @notice Returns the amount of T requested unstaking right now
    ///         NOTE: It shows the REQUESTED amount, not unstaked right now
    ///               You may check in unclaimedReward() about the amount of already unstaked
    /// @param  _staker  the address of the staking provider
    /// @return uint96  shows how much the user requested unstaking right now
    function currUnstakingAmount(
        address _staker
    ) external view returns (uint96);

    /// @notice Get total uncliamed a user's reward plus completed unstaking
    ///
    /// @param  _staker the address of the staking provider
    /// @return uint96  shows how much the allocated reward including with the unstaked amount
    function unclaimedReward(address _staker) external view returns (uint96);

    /// @notice Check whether the given period is unstakable or not
    /// @param period the unique number of the period
    /// @return bool return that the given period is unstakble or not
    function unstakeExecutable(uint16 period) external view returns (bool);
}
