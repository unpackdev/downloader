// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ITWBalance.sol";
import "./IStaking.sol";

interface IveORN is ITWBalance,IStaking
{

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
    function totalSupply(uint256 ts) external view returns (uint256);
    function totalSupply0() external view returns (uint256);//balance on start timestamp

    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);
    function balanceOf(address account, uint256 ts) external view returns (uint256);
    function balanceOf0(address account) external view returns (uint256);//balance on start timestamp

    function balanceTokenOf(address account) external view  returns (uint256);

    /// @notice Returns the number of decimals used to get its user representation.
    function decimals() external view returns (uint8);
    
    function name() pure external returns(string memory);
    function symbol() pure external returns(string memory);
 

    function ORN() external view returns (address);

    function lockTime(address account) external view returns (uint48);

    
    //staking ORN
    function create_lock(uint256 _value, uint256 _unlock_time) external;
    //function deposit_for(address _addr, uint256 _value) external;
    function increase_amount(uint256 _value) external;
    function increase_unlock_time(uint256 _unlock_time) external;
    function increase_unlock_period(uint256 unlock_period) external;
    function create_lock_period(uint256 _value, uint256 unlock_period) external;

    function withdraw() external;
    function claimReward() external;

}
