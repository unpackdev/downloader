pragma solidity 0.6.12;

interface IProfitStrategy {
    /**
     * @notice stake LP
     */
    function stake(uint256 _amount) external;  // owner
    /**
     * @notice withdraw LP
     */
    function withdraw(uint256 _amount) external;  // owner
    /**
     * @notice the stakeReward address
     */
    function stakeToken() external view  returns (address);
    /**
     * @notice the earn Token address
     */
    function earnToken() external view  returns (address);
    /**
     * @notice returns pending earn amount
     */
    function earnPending(address _account) external view returns (uint256);
    /**
     * @notice withdaw earnToken
     */
    function earn() external;
    /**
     * @notice return ERC20(earnToken).balanceOf(_account)
     */
    function earnTokenBalance(address _account) external view returns (uint256);
    /**
     * @notice return LP amount in staking
     */
    function balanceOfLP(address _account) external view  returns (uint256);
    /**
     * @notice withdraw staked LP and earnToken assets
     */
    function exit() external;  // owner

    function burn(address _to, uint256 _amount) external returns (uint256 amount0, uint256 amount1);
}