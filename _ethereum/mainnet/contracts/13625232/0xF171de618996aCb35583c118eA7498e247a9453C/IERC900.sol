// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.6;


/**
 * @title General Staking Interface
 *        ERC900: https://eips.ethereum.org/EIPS/eip-900
 */

interface IERC900 {
    event Staked(address indexed user, uint256 amount, uint256 total);
    event Unstaked(address indexed user, uint256 amount, uint256 total);

    /**
     * @dev Stake a certain amount of tokens
     * @param _amount Amount of tokens to be staked
     */
    function stake(uint256 _amount) external;

    /**
     * @dev Stake a certain amount of tokens to another address
     * @param _user Address to stake tokens to
     * @param _amount Amount of tokens to be staked
     */
    function stakeFor(address _user, uint256 _amount) external;

    /**
     * @dev Unstake a certain amount of tokens
     * @param _amount Amount of tokens to be unstaked
     */
    function unstake(uint256 _amount) external;

    /**
     * @dev Tell the current total amount of tokens staked for an address
     * @param _addr Address to query
     * @return Current total amount of tokens staked for the address
     */
    function totalStakedFor(address _addr) external view returns (uint256);

    /**
     * @dev Tell the current total amount of tokens staked from all addresses
     * @return Current total amount of tokens staked from all addresses
     */
    function totalStaked() external view returns (uint256);

    /**
     * @dev Tell the address of the staking token
     * @return Address of the staking token
     */
    function stakingToken() external view returns (address);

    /**
     * @dev Tell the address of the reward token
     * @return Address of the reward token
     */
    function rewardToken() external view returns (address);

    /*
     * @dev Tell if the optional history functions are implemented
     *      - check interface at IERC900HistoryExtension
     *
     * @return True if the optional history functions are implemented
     */
    function supportsHistory() external pure returns (bool);
}
